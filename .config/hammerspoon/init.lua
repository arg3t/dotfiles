local mod = { "alt" }
local modShift = { "alt", "shift" }

local workspaceCount = 10

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

-- Mission Control has no scripted "set desktop count", so the only way to add
-- one is to press the + button through the accessibility API. Keeping
-- Mission Control open until the last add keeps it to a single visual flash.
local function ensureWorkspaces()
  local missing = workspaceCount - #userSpaces()
  if missing <= 0 then
    return
  end

  for i = 1, missing do
    local ok, err = hs.spaces.addSpaceToScreen(hs.screen.mainScreen(), i == missing)
    if not ok then
      hs.spaces.closeMissionControl()
      hs.alert.show("Could not add desktop: " .. tostring(err))
      return
    end
  end
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

  -- Mission Control only offers direct shortcuts for desktops 1-9; the tenth
  -- has to be walked to.
  if index <= 9 then
    hs.eventtap.keyStroke({ "ctrl" }, tostring(index), 0)
  end
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
  local ev = hs.eventtap.event
  local released = false

  local function release()
    if released then
      return
    end
    released = true

    ev.newMouseEvent(ev.types.leftMouseUp, { x = grab.x, y = grab.y + 12 }):post()
    hs.mouse.absolutePosition(origin)

    -- Only chase the window if it actually travelled; focusing a window that
    -- stayed behind would drag us straight back to the desktop we left.
    hs.timer.doAfter(0.1, function()
      for _, spaceID in ipairs(hs.spaces.windowSpaces(win) or {}) do
        if spaceID == target then
          win:focus()
          return
        end
      end
    end)
  end

  win:focus()
  ev.newMouseEvent(ev.types.leftMouseDown, grab):post()

  -- A single 2px nudge is below the drag threshold, and usleep would block the
  -- run loop before the events could be delivered.
  hs.timer.doAfter(0.05, function()
    ev.newMouseEvent(ev.types.leftMouseDragged, { x = grab.x, y = grab.y + 6 }):post()
    ev.newMouseEvent(ev.types.leftMouseDragged, { x = grab.x, y = grab.y + 12 }):post()

    gotoWorkspace(index)

    -- Switching can take several ctrl+arrow steps, so hold the drag until we
    -- arrive rather than guessing a duration.
    local timeout = hs.timer.doAfter(3, release)
    hs.timer.waitUntil(function()
      return hs.spaces.focusedSpace() == target
    end, function()
      timeout:stop()
      hs.timer.doAfter(0.25, release)
    end, 0.05)
  end)
end

for index = 1, workspaceCount do
  local key = index == 10 and "0" or tostring(index)
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

-- Ctrl+C/V/X/W behave like they do everywhere that is not macOS, except in
-- terminals, where ctrl+c must stay SIGINT and ctrl+w deletes a word.
-- Terminals use ctrl+shift+c/v.
-- Match terminals by bundle identifier, not display name: a kitty quake panel
-- reports an unstable name (kitty / .kitty-wrapped / nothing) but always keeps
-- the same bundle id, and a non-activating overlay may not be the frontmost app
-- at all, so we also consult the focused window's owner.
local terminalBundles = {
  ["net.kovidgoyal.kitty"] = true,
  ["net.kovidgoyal.kitty-quick-access"] = true,
  ["com.apple.Terminal"] = true,
  ["com.googlecode.iterm2"] = true,
  ["com.github.wez.wezterm"] = true,
  ["org.alacritty"] = true,
}

local terminalApps = {
  ["kitty"] = true,
  ["kitty-quick-access"] = true,
  [".kitty-wrapped"] = true,
  ["Terminal"] = true,
  ["iTerm2"] = true,
  ["WezTerm"] = true,
  ["Alacritty"] = true,
}

local function appIsTerminal(app)
  if not app then
    return false
  end
  local bundle = app.bundleID and app:bundleID()
  if bundle and terminalBundles[bundle] then
    return true
  end
  return terminalApps[app:name()] == true
end

local function isTerminalFocused()
  if appIsTerminal(hs.application.frontmostApplication()) then
    return true
  end
  local win = hs.window.focusedWindow()
  return appIsTerminal(win and win:application())
end

-- Each entry maps a ctrl+<key> chord to the macOS modifier that produces the
-- same intent: cmd for clipboard/select-all, alt for word-wise arrow motion.
local remapKeys = {
  c = "cmd",
  v = "cmd",
  x = "cmd",
  w = "cmd",
  a = "cmd",
  left = "alt",
  right = "alt",
}

ctrlRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local flags = event:getFlags()
  if not flags.ctrl or flags.cmd or flags.alt or flags.shift or flags.fn then
    return false
  end

  local key = hs.keycodes.map[event:getKeyCode()]
  local target = remapKeys[key]
  if not target then
    return false
  end

  if isTerminalFocused() then
    return false
  end

  return true, {
    hs.eventtap.event.newKeyEvent({ target }, key, true),
    hs.eventtap.event.newKeyEvent({ target }, key, false),
  }
end)
ctrlRemap:start()

-- App-specific ctrl remaps. Unlike ctrlRemap above (which only fires when ctrl
-- is the sole modifier and blanket-maps to cmd), these target one app at a time
-- and can translate to arbitrary modifier combos, so ctrl+shift+p can become
-- cmd+shift+p. Each entry: appName -> list of { from = {mods, key}, to = {mods, key} }.
local appKeyRemaps = {
  ["firefox"] = {
    { from = { {}, "f" }, to = { { "cmd" }, "f" } },
  },
  ["Google Chrome"] = {
    { from = { {}, "f" }, to = { { "cmd" }, "f" } },
  },
  ["Zed"] = {
    { from = { {}, "p" }, to = { { "cmd" }, "p" } },
    { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
  },
  ["Cursor"] = {
    { from = { {}, "p" }, to = { { "cmd" }, "p" } },
    { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
  },
}

-- Firefox reports its app name as "firefox" via the running-application API even
-- though the bundle is "Firefox"; match both to be safe.
local appNameAliases = {
  ["Firefox"] = "firefox",
}

local function modsMatch(flags, wanted)
  local want = { ctrl = true }
  for _, m in ipairs(wanted) do
    want[m] = true
  end
  for _, m in ipairs({ "cmd", "alt", "shift", "fn" }) do
    if (flags[m] and true or false) ~= (want[m] and true or false) then
      return false
    end
  end
  return flags.ctrl == true
end

appCtrlRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local flags = event:getFlags()
  if not flags.ctrl then
    return false
  end

  local app = hs.application.frontmostApplication()
  if not app then
    return false
  end
  local name = app:name()
  name = appNameAliases[name] or name

  local rules = appKeyRemaps[name]
  if not rules then
    return false
  end

  local key = hs.keycodes.map[event:getKeyCode()]
  for _, rule in ipairs(rules) do
    if key == rule.from[2] and modsMatch(flags, rule.from[1]) then
      return true, {
        hs.eventtap.event.newKeyEvent(rule.to[1], rule.to[2], true),
        hs.eventtap.event.newKeyEvent(rule.to[1], rule.to[2], false),
      }
    end
  end

  return false
end)
appCtrlRemap:start()

-- Ctrl+click opens a link in a new tab in Firefox by translating the click to
-- cmd+click (the macOS "background tab" chord). Only the ctrl modifier may be
-- held, and only when Firefox is frontmost.
local mouseTabApps = {
  ["firefox"] = true,
  ["Firefox"] = true,
  ["Google Chrome"] = true,
}

ctrlClickRemap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(event)
  local flags = event:getFlags()
  if not flags.ctrl or flags.cmd or flags.alt or flags.shift or flags.fn then
    return false
  end

  local app = hs.application.frontmostApplication()
  if not (app and mouseTabApps[app:name()]) then
    return false
  end

  event:setFlags({ cmd = true })
  return false
end)
ctrlClickRemap:start()

-- Menu bar indicator: the current desktop as D1, D2, ...
desktopIndicator = hs.menubar.new(true, "hammerspoonDesktops")

local function refreshIndicator()
  if not desktopIndicator then
    return
  end

  local spaces = userSpaces()
  local current = indexOf(spaces, hs.spaces.focusedSpace())

  desktopIndicator:setTitle("D" .. (current or "?"))

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

ensureWorkspaces()
refreshIndicator()

hs.hotkey.bind(modShift, "i", function()
  local spaces = userSpaces()
  local current = hs.spaces.focusedSpace()
  hs.alert.show(("desktop %s of %d"):format(indexOf(spaces, current) or "?", #spaces))
end)

hs.hotkey.bind(modShift, "d", function()
  local app = hs.application.frontmostApplication()
  local function describe(a)
    if not a then return "?" end
    local b = a.bundleID and a:bundleID() or "?"
    return (a:name() or "?") .. " [" .. (b or "?") .. "]"
  end
  local win = hs.window.focusedWindow()
  hs.alert.show(
    "frontmost: " .. describe(app)
    .. "  |  focused-win: " .. describe(win and win:application())
    .. "  |  terminal? " .. tostring(isTerminalFocused())
  )
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
