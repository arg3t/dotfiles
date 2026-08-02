-- Hammerspoon configuration for macOS.
--
-- Provides the two pieces of the Hyprland workflow that macOS lacks:
--   1. Numbered desktops, including "move this window to desktop N".
--   2. A hotkey for kitty's built-in Quake-style quick access terminal.
--
-- Everything else (tiling, launching, clipboard) is left to macOS and SuperCmd.

local mod = { "alt" }
local modShift = { "alt", "shift" }

local workspaceCount = 9

hs.window.animationDuration = 0

-- Ordered list of ordinary (non-fullscreen) desktops on the focused screen.
local function userSpaces()
  local spaces = hs.spaces.spacesForScreen(hs.screen.mainScreen())
  if not spaces then
    return {}
  end

  local result = {}
  for _, spaceID in ipairs(spaces) do
    if hs.spaces.spaceType(spaceID) == "user" then
      table.insert(result, spaceID)
    end
  end
  return result
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

  -- Fast path: macOS's own ctrl+<n> shortcut switches instantly and without a
  -- Mission Control animation.
  hs.eventtap.keyStroke({ "ctrl" }, tostring(index), 0)

  -- That shortcut is off by default in System Settings. If nothing moved, fall
  -- back to the API, which works unconditionally but flashes Mission Control.
  hs.timer.doAfter(0.25, function()
    if hs.spaces.focusedSpace() ~= target then
      hs.spaces.gotoSpace(target)
    end
  end)
end

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

  local ok, err = hs.spaces.moveWindowToSpace(win, target)
  if not ok then
    hs.alert.show("Move failed: " .. tostring(err))
    return
  end

  gotoWorkspace(index)
  hs.timer.doAfter(0.4, function()
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

-- Quick access terminal ------------------------------------------------------
--
-- kitty ships a Quake-style panel since 0.42. Running the kitten toggles it, so
-- there is no window bookkeeping to do here. Geometry lives in
-- ~/.config/kitty/quick-access-terminal.conf.

local function kittenPath()
  local candidates = {
    os.getenv("HOME") .. "/.nix-profile/bin/kitten",
    "/run/current-system/sw/bin/kitten",
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/kitten",
    "/opt/homebrew/bin/kitten",
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return nil
end

hs.hotkey.bind(mod, "s", function()
  local kitten = kittenPath()
  if not kitten then
    hs.alert.show("kitten not found on PATH")
    return
  end
  hs.task.new(kitten, nil, { "quick-access-terminal" }):start()
end)

-- Diagnostics ----------------------------------------------------------------

hs.hotkey.bind(modShift, "i", function()
  local spaces = userSpaces()
  local current = hs.spaces.focusedSpace()
  local index = "?"
  for i, spaceID in ipairs(spaces) do
    if spaceID == current then
      index = tostring(i)
    end
  end
  hs.alert.show(("desktop %s of %d"):format(index, #spaces))
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
