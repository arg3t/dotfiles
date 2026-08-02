local mod = { "alt" }
local modShift = { "alt", "shift" }

local workspaceCount = 9

hs.window.animationDuration = 0

local function screenSpaces()
  return hs.spaces.spacesForScreen(hs.screen.mainScreen()) or {}
end

local function userSpaces()
  local result = {}
  for _, spaceID in ipairs(screenSpaces()) do
    if hs.spaces.spaceType(spaceID) == "user" then
      table.insert(result, spaceID)
    end
  end
  return result
end

local function indexOf(list, value)
  for i, item in ipairs(list) do
    if item == value then
      return i
    end
  end
  return nil
end

-- ctrl+left/right are enabled by default, unlike ctrl+<number>, so walking one
-- space at a time always works. Steps are chained rather than sent in a burst
-- because macOS drops keystrokes that arrive mid-transition.
local function stepToward(target, budget)
  if budget <= 0 or hs.spaces.focusedSpace() == target then
    return
  end

  local all = screenSpaces()
  local from = indexOf(all, hs.spaces.focusedSpace())
  local to = indexOf(all, target)
  if not from or not to or from == to then
    return
  end

  hs.eventtap.keyStroke({ "ctrl" }, to > from and "right" or "left", 0)
  hs.timer.doAfter(0.12, function()
    stepToward(target, budget - 1)
  end)
end

local function gotoWorkspace(index)
  local target = userSpaces()[index]
  if not target then
    hs.alert.show("No desktop " .. index .. " — add it in Mission Control")
    return
  end
  if hs.spaces.focusedSpace() == target then
    return
  end

  hs.eventtap.keyStroke({ "ctrl" }, tostring(index), 0)
  hs.timer.doAfter(0.15, function()
    stepToward(target, #screenSpaces())
  end)
end

-- hs.spaces.moveWindowToSpace has been broken since macOS 15: it returns true
-- and does nothing. Dragging the title bar while switching spaces is what a
-- human would do, and it still works.
local function moveWindowToWorkspace(index)
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local target = userSpaces()[index]
  if not target then
    hs.alert.show("No desktop " .. index .. " — add it in Mission Control")
    return
  end
  if hs.spaces.focusedSpace() == target then
    return
  end

  local frame = win:frame()
  local origin = hs.mouse.absolutePosition()
  local grab = { x = frame.x + frame.w / 2, y = frame.y + 8 }
  local events = hs.eventtap.event

  win:focus()
  events.newMouseEvent(events.types.leftMouseDown, grab):post()
  hs.timer.usleep(60000)
  events.newMouseEvent(events.types.leftMouseDragged, { x = grab.x, y = grab.y + 2 }):post()

  gotoWorkspace(index)

  hs.timer.doAfter(0.9, function()
    events.newMouseEvent(events.types.leftMouseUp, { x = grab.x, y = grab.y + 2 }):post()
    hs.mouse.absolutePosition(origin)
    win:focus()
  end)
end

for index = 1, workspaceCount do
  local key = tostring(index)
  hs.hotkey.bind(mod, key, function()
    gotoWorkspace(index)
  end)
  hs.hotkey.bind(modShift, key, function()
    moveWindowToWorkspace(index)
  end)
end

-- Snapping. screen:frame() is the usable area, so these stop short of the menu
-- bar and Dock instead of going native fullscreen.
local noSnapApps = {
  ["SuperCmd"] = true,
}

local function snap(shape)
  return function()
    local win = hs.window.focusedWindow()
    if not win then
      return
    end

    local app = win:application()
    if app and noSnapApps[app:name()] then
      return
    end

    local f = win:screen():frame()
    win:setFrame(shape(f))
  end
end

hs.hotkey.bind(mod, "f", snap(function(f)
  return f
end))

hs.hotkey.bind(mod, "left", snap(function(f)
  return { x = f.x, y = f.y, w = f.w / 2, h = f.h }
end))

hs.hotkey.bind(mod, "right", snap(function(f)
  return { x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h }
end))

hs.hotkey.bind(mod, "up", snap(function(f)
  return { x = f.x, y = f.y, w = f.w, h = f.h / 2 }
end))

hs.hotkey.bind(mod, "down", snap(function(f)
  return { x = f.x, y = f.y + f.h / 2, w = f.w, h = f.h / 2 }
end))

hs.hotkey.bind(mod, "q", function()
  local win = hs.window.focusedWindow()
  if win then
    win:close()
  end
end)

local function binPath(name)
  local candidates = {
    os.getenv("HOME") .. "/.nix-profile/bin/" .. name,
    "/run/current-system/sw/bin/" .. name,
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/" .. name,
    "/opt/homebrew/bin/" .. name,
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return nil
end

-- Tasks inherit Hammerspoon's own working directory (~/.hammerspoon), which is
-- not where you want a shell to start.
local function run(name, args)
  local bin = binPath(name)
  if not bin then
    hs.alert.show(name .. " not found")
    return
  end
  local task = hs.task.new(bin, nil, args)
  task:setWorkingDirectory(os.getenv("HOME"))
  task:start()
end

hs.hotkey.bind(mod, "s", function()
  run("kitten", { "quick-access-terminal" })
end)

hs.hotkey.bind(mod, "c", function()
  hs.application.launchOrFocus("SuperCmd")
end)

hs.hotkey.bind(mod, "return", function()
  run("kitty", { "--single-instance", "--directory", os.getenv("HOME") })
  hs.timer.doAfter(0.3, function()
    local app = hs.application.get("kitty")
    if app then
      app:activate()
    end
  end)
end)

-- Ctrl+C/V/X behave like they do everywhere that is not macOS, except in
-- terminals, where ctrl+c must stay SIGINT. Terminals use ctrl+shift+c/v.
local terminalApps = {
  ["kitty"] = true,
  ["Terminal"] = true,
  ["iTerm2"] = true,
  ["WezTerm"] = true,
  ["Alacritty"] = true,
}

local clipboardKeys = { c = true, v = true, x = true }

clipboardRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local flags = event:getFlags()
  if not flags.ctrl or flags.cmd or flags.alt or flags.shift or flags.fn then
    return false
  end

  local key = hs.keycodes.map[event:getKeyCode()]
  if not clipboardKeys[key] then
    return false
  end

  local app = hs.application.frontmostApplication()
  if app and terminalApps[app:name()] then
    return false
  end

  return true, {
    hs.eventtap.event.newKeyEvent({ "cmd" }, key, true),
    hs.eventtap.event.newKeyEvent({ "cmd" }, key, false),
  }
end)
clipboardRemap:start()

-- Menu bar indicator: filled dot for the active desktop, hollow for the rest.
desktopIndicator = hs.menubar.new(true, "hammerspoonDesktops")

local function refreshIndicator()
  if not desktopIndicator then
    return
  end

  local spaces = userSpaces()
  local current = indexOf(spaces, hs.spaces.focusedSpace())

  local dots = {}
  for i = 1, #spaces do
    table.insert(dots, i == current and "●" or "○")
  end
  desktopIndicator:setTitle(table.concat(dots))

  local menu = {}
  for i = 1, #spaces do
    table.insert(menu, {
      title = "Desktop " .. i,
      checked = i == current,
      fn = function()
        gotoWorkspace(i)
      end,
    })
  end
  desktopIndicator:setMenu(menu)
end

-- Each macOS space keeps its own desktop picture and System Events can only
-- reach the visible one, so re-apply the current wallpaper on every switch.
spaceWatcher = hs.spaces.watcher.new(function()
  run("set-darwin-background", { "--reapply" })
  refreshIndicator()
end)
spaceWatcher:start()

screenWatcher = hs.screen.watcher.new(refreshIndicator)
screenWatcher:start()

refreshIndicator()

hs.hotkey.bind(modShift, "i", function()
  local spaces = userSpaces()
  local current = hs.spaces.focusedSpace()
  hs.alert.show(("desktop %s of %d"):format(indexOf(spaces, current) or "?", #spaces))
end)

hs.hotkey.bind(modShift, "r", hs.reload)

configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end):start()

hs.alert.show("Hammerspoon loaded")
