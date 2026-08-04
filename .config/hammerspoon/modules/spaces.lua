local config = require("config")

local M = {}
local rebindWorkspaceHotkeys

local function isBuiltInScreen(screen)
  local name = (screen:name() or ""):lower()
  -- macOS reports built-in panels as either "Built-in ..." or "Color LCD".
  return name:find("built%-in") ~= nil or name:find("color lcd") ~= nil
end

local function workspaceCountForScreen(screen)
  if isBuiltInScreen(screen) then
    return config.builtInWorkspaceCount
  end
  return config.peripheralWorkspaceCount
end

local function focusedScreen()
  local win = hs.window.focusedWindow()
  return (win and win:screen()) or hs.screen.mainScreen()
end

local function screenSpaces(screen)
  return hs.spaces.spacesForScreen(screen or focusedScreen()) or {}
end

local function userSpaces(screen)
  local result = {}
  for _, spaceID in ipairs(screenSpaces(screen)) do
    if hs.spaces.spaceType(spaceID) == "user" then
      table.insert(result, spaceID)
    end
  end
  return result
end

-- Mission Control provisions Spaces asynchronously, so every pass re-checks
-- after a delay instead of trusting that the previous one landed. The attempt
-- budget keeps a display that refuses to gain Spaces from looping forever.
local maxEnsureAttempts = 5

local function ensureWorkspaces(attempt)
  attempt = attempt or 1

  local screens = hs.screen.allScreens()
  local multiMonitor = #screens > 1
  if multiMonitor and not hs.spaces.screensHaveSeparateSpaces() then
    hs.alert.show("Enable Displays Have Separate Spaces for per-monitor desktops")
    return
  end

  -- Hotkeys can only bind to Spaces that already exist, so rebind after every
  -- pass instead of once at startup.
  local function settle()
    if rebindWorkspaceHotkeys then
      rebindWorkspaceHotkeys()
    end
  end

  local function retry()
    if attempt >= maxEnsureAttempts then
      hs.spaces.closeMissionControl()
      settle()
      return
    end
    hs.timer.doAfter(0.75, function()
      ensureWorkspaces(attempt + 1)
    end)
  end

  -- Single-monitor mode preserves the user's existing Spaces. In multi-monitor
  -- mode, reconcile each display to its configured count before adding missing
  -- Spaces, so switching between topologies does not leave stale desktops.
  if multiMonitor then
    local active = {}
    for _, spaceID in pairs(hs.spaces.activeSpaces() or {}) do
      active[spaceID] = true
    end

    local removals = {}
    for _, screen in ipairs(screens) do
      local spaces = userSpaces(screen)
      local desired = workspaceCountForScreen(screen)
      if #spaces > desired then
        for i = #spaces, desired + 1, -1 do
          if active[spaces[i]] then
            local frame = screen:frame()
            hs.mouse.absolutePosition({
              x = frame.x + frame.w / 2,
              y = frame.y + frame.h / 2,
            })
            hs.eventtap.keyStroke({ "ctrl" }, "1", 0)
            retry()
            return
          end
          table.insert(removals, spaces[i])
        end
      end
    end

    if #removals > 0 then
      for i, spaceID in ipairs(removals) do
        local ok, err = hs.spaces.removeSpace(spaceID, i == #removals)
        if not ok then
          hs.spaces.closeMissionControl()
          hs.alert.show("Could not remove extra desktop: " .. tostring(err))
          return
        end
      end
      retry()
      return
    end
  end

  local pending = {}
  for _, screen in ipairs(screens) do
    local missing = workspaceCountForScreen(screen) - #userSpaces(screen)
    for _ = 1, math.max(0, missing) do
      table.insert(pending, screen)
    end
  end

  for i, screen in ipairs(pending) do
    local ok, err = hs.spaces.addSpaceToScreen(screen, i == #pending)
    if not ok then
      hs.spaces.closeMissionControl()
      hs.alert.show("Could not add desktop: " .. tostring(err))
      return
    end
  end
  if #pending > 0 then
    retry()
  else
    settle()
  end
end

local function orderedScreens()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b)
    local aBuiltIn = isBuiltInScreen(a)
    local bBuiltIn = isBuiltInScreen(b)
    if aBuiltIn ~= bBuiltIn then
      return aBuiltIn
    end
    local aKey = (a:name() or "") .. "\0" .. (a:getUUID() or "")
    local bKey = (b:name() or "") .. "\0" .. (b:getUUID() or "")
    return aKey < bKey
  end)
  return screens
end

local function monitorInventory()
  local builtin
  local peripherals = {}
  for _, screen in ipairs(orderedScreens()) do
    if isBuiltInScreen(screen) then
      builtin = screen
    else
      table.insert(peripherals, screen)
    end
  end
  if not builtin and #peripherals == 1 then
    builtin = peripherals[1]
    peripherals = {}
  end
  return builtin, peripherals
end

local function workspaceTargets()
  local screens = hs.screen.allScreens()
  if #screens > 1 and not hs.spaces.screensHaveSeparateSpaces() then
    return {}
  end

  local builtin, peripherals = monitorInventory()
  local mappings = config.desktopMapping
  if #peripherals == 0 then
    mappings = {}
    local spaceCount = math.min(builtin and #userSpaces(builtin) or config.builtInWorkspaceCount, 10)
    for space = 1, spaceCount do
      table.insert(mappings, {
        key = space == 10 and "0" or tostring(space),
        monitor = "builtin",
        space = space,
      })
    end
  end

  local function resolveScreen(mapping)
    if mapping.monitor == "builtin" then
      return builtin
    end
    return peripherals[mapping.index]
  end

  local result = {}
  for aliasIndex, mapping in ipairs(mappings) do
    local screen = resolveScreen(mapping)
    if screen then
      local spaces = userSpaces(screen)
      local spaceID = spaces[mapping.space]
      if spaceID then
        table.insert(result, {
          aliasIndex = aliasIndex,
          key = mapping.key,
          screen = screen,
          spaceID = spaceID,
          localIndex = mapping.space,
        })
      end
    end
  end
  return result
end

local function targetForKey(key)
  for _, target in ipairs(workspaceTargets()) do
    if target.key == key then
      return target
    end
  end
  return nil
end

local movingWindow = false
local gotoWorkspace
local function windowIsOnSpace(win, spaceID)
  for _, currentSpaceID in ipairs(hs.spaces.windowSpaces(win) or {}) do
    if currentSpaceID == spaceID then
      return true
    end
  end
  return false
end

local function dragWindowToWorkspace(key, win, target)
  if win:screen():getUUID() ~= target.screen:getUUID() then
    win:moveToScreen(target.screen)
    win:focus()
  end

  local origin = hs.mouse.absolutePosition()
  local zoomRect = win:zoomButtonRect()
  local grab
  if zoomRect then
    grab = {
      x = zoomRect.x + zoomRect.w / 2,
      y = zoomRect.y + zoomRect.h + 6,
    }
  else
    -- Some non-standard windows have no zoom button; retain the old fallback.
    local frame = win:frame()
    grab = { x = frame.x + frame.w / 2, y = frame.y + 8 }
  end
  local dragPoint = { x = grab.x, y = grab.y + 12 }
  local ev = hs.eventtap.event
  local released = false
  local timeout
  local safetyTimeout

  local function finish()
    hs.mouse.absolutePosition(origin)
    movingWindow = false
    hs.timer.doAfter(0.1, function()
      if windowIsOnSpace(win, target.spaceID) then
        win:focus()
      else
        hs.alert.show("Could not move window to Option+" .. key)
      end
    end)
  end

  local function release()
    if released then
      return
    end
    released = true
    if timeout then
      timeout:stop()
    end
    if safetyTimeout then
      safetyTimeout:stop()
    end

    -- Put the real pointer at the release point before posting mouse-up. This
    -- matters for apps such as Slack that keep the drag capture otherwise.
    hs.mouse.absolutePosition(dragPoint)
    ev.newMouseEvent(ev.types.leftMouseUp, dragPoint):post()
    hs.timer.doAfter(0.05, finish)
  end

  win:focus()
  hs.mouse.absolutePosition(grab)
  ev.newMouseEvent(ev.types.leftMouseDown, grab):post()

  -- Give custom title bars time to enter drag mode before switching Spaces.
  hs.timer.doAfter(0.08, function()
    if released then
      return
    end
    ev.newMouseEvent(ev.types.leftMouseDragged, { x = grab.x, y = grab.y + 6 }):post()
    hs.timer.doAfter(0.04, function()
      if released then
        return
      end
      ev.newMouseEvent(ev.types.leftMouseDragged, dragPoint):post()
      gotoWorkspace(key, true)

      timeout = hs.timer.doAfter(3, release)
      safetyTimeout = hs.timer.doAfter(6, release)
      hs.timer.waitUntil(function()
        return hs.spaces.focusedSpace() == target.spaceID
      end, function()
        if timeout then
          timeout:stop()
        end
        hs.timer.doAfter(0.25, release)
      end, 0.05)
    end)
  end)
end
local function movePointerToScreen(screen)
  local frame = screen:frame()
  hs.mouse.absolutePosition({
    x = frame.x + frame.w / 2,
    y = frame.y + frame.h / 2,
  })
end

-- win:focus() over the AX API is unreliable right after a Space switch, so
-- synthesize a real click just below the window's zoom button to focus it (the
-- same grab point the drag path uses), then recenter the pointer on the display
-- so the cursor does not linger on the title bar.
local function clickToFocusWindow(win)
  local zoomRect = win:zoomButtonRect()
  local point
  if zoomRect then
    point = { x = zoomRect.x + zoomRect.w / 2, y = zoomRect.y + zoomRect.h + 6 }
  else
    local frame = win:frame()
    point = { x = frame.x + frame.w / 2, y = frame.y + 8 }
  end
  local ev = hs.eventtap.event
  hs.mouse.absolutePosition(point)
  ev.newMouseEvent(ev.types.leftMouseDown, point):post()
  ev.newMouseEvent(ev.types.leftMouseUp, point):post()
  movePointerToScreen(win:screen())
end

-- macOS "Switch to Desktop N" activates the Space but leaves keyboard focus on
-- the desktop, not a window. Click the frontmost standard window that lives on
-- the target Space so typing lands there after a switch.
local function focusFrontmostWindowOnSpace(target)
  for _, win in ipairs(hs.window.orderedWindows()) do
    if win:isStandard()
        and win:screen():getUUID() == target.screen:getUUID()
        and windowIsOnSpace(win, target.spaceID) then
      clickToFocusWindow(win)
      return true
    end
  end
  return false
end

-- The Ctrl+N switch is async; poll until the target Space is active (bounded so
-- a superseded switch cannot leak timers), then focus its frontmost window.
local function focusAfterSwitch(target, attempt)
  attempt = attempt or 1
  if hs.spaces.focusedSpace() ~= target.spaceID then
    if attempt < 20 then
      hs.timer.doAfter(0.05, function()
        focusAfterSwitch(target, attempt + 1)
      end)
    end
    return
  end
  focusFrontmostWindowOnSpace(target)
end

-- macOS "Switch to Desktop N" (Ctrl+N) numbers desktops globally across all
-- displays in Mission Control order, not per monitor. Ctrl+0 is desktop 10.
local function globalDesktopIndex(target)
  local index = 0
  for _, screen in ipairs(orderedScreens()) do
    if screen:getUUID() == target.screen:getUUID() then
      return index + target.localIndex
    end
    index = index + #userSpaces(screen)
  end
  return target.localIndex
end

gotoWorkspace = function(key, allowWhileMoving)
  if movingWindow and not allowWhileMoving then
    hs.alert.show("Finish moving the current window first")
    return
  end

  local target = targetForKey(key)
  if not target then
    hs.alert.show("No desktop mapping for Option+" .. key)
    return
  end
  if not allowWhileMoving then
    local pointerScreen = hs.screen.find(hs.mouse.absolutePosition())
    local activeScreen = focusedScreen()
    if (not pointerScreen or pointerScreen:getUUID() ~= target.screen:getUUID())
        or activeScreen:getUUID() ~= target.screen:getUUID() then
      -- Ctrl+N switches globally, but keep the cursor on the target display so
      -- the pointer follows the desktop switch.
      movePointerToScreen(target.screen)
    end
  end

  if hs.spaces.focusedSpace() == target.spaceID then
    return
  end

  -- Ctrl+1..9 select desktops 1-9 globally; Ctrl+0 selects desktop 10.
  local globalIndex = globalDesktopIndex(target)
  if globalIndex >= 1 and globalIndex <= 10 then
    hs.eventtap.keyStroke({ "ctrl" }, globalIndex == 10 and "0" or tostring(globalIndex), 0)
    -- macOS activates the Space but leaves keyboard focus off any window. On a
    -- plain switch, focus the destination's frontmost window once it lands; the
    -- window-move path focuses the moved window itself, so skip it there.
    if not allowWhileMoving then
      focusAfterSwitch(target)
    end
  end
end

-- Window movement always uses the Ctrl shortcut while dragging; the native
-- hs.spaces.moveWindowToSpace API is intentionally not used.
local function moveWindowToWorkspace(key)
  if movingWindow then
    hs.alert.show("A window move is already in progress")
    return
  end

  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local target = targetForKey(key)
  if not target then
    hs.alert.show("No desktop mapping for Option+" .. key)
    return
  end
  if hs.spaces.focusedSpace() == target.spaceID
      and win:screen():getUUID() == target.screen:getUUID() then
    return
  end

  movingWindow = true
  dragWindowToWorkspace(key, win, target)
end

local workspaceHotkeys = {}

rebindWorkspaceHotkeys = function()
  for _, hotkey in ipairs(workspaceHotkeys) do
    hotkey:delete()
  end
  workspaceHotkeys = {}

  local targets = workspaceTargets()
  for _, target in ipairs(targets) do
    local key = target.key
    local switchHotkey = hs.hotkey.bind(config.mod, key, function()
      gotoWorkspace(key)
    end)
    local moveHotkey = hs.hotkey.bind(config.modShift, key, function()
      moveWindowToWorkspace(key)
    end)
    if switchHotkey then
      table.insert(workspaceHotkeys, switchHotkey)
    end
    if moveHotkey then
      table.insert(workspaceHotkeys, moveHotkey)
    end
  end
  local lastTarget = targets[#targets]
  if lastTarget then
    local lastDesktopHotkey = hs.hotkey.bind(config.mod, ".", function()
      gotoWorkspace(lastTarget.key)
    end)
    if lastDesktopHotkey then
      table.insert(workspaceHotkeys, lastDesktopHotkey)
    end
  end
end
M.gotoWorkspace = gotoWorkspace
M.moveWindowToWorkspace = moveWindowToWorkspace

function M.targets()
  return workspaceTargets()
end

function M.indexForSpace(targets, spaceID)
  for _, target in ipairs(targets) do
    if target.spaceID == spaceID then
      return target.aliasIndex
    end
  end
  return nil
end

function M.aliasCount(targets)
  local count = 0
  for _, target in ipairs(targets) do
    count = math.max(count, target.aliasIndex)
  end
  return count
end

function M.ensure()
  ensureWorkspaces()
end

function M.onScreenChange(activeScreenChanged)
  if not activeScreenChanged then
    ensureWorkspaces()
    rebindWorkspaceHotkeys()
  end
end

function M.start()
  ensureWorkspaces()
  rebindWorkspaceHotkeys()
end

return M
