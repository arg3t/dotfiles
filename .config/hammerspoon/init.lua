-- Hammerspoon configuration for macOS.
--
-- Provides the two pieces of the Hyprland workflow that macOS lacks:
--   1. Numbered desktops, including "move this window to desktop N".
--   2. A Quake-style drop-down scratch terminal.
--
-- Everything else (tiling, launching, clipboard) is left to macOS and SuperCmd.

local mod = { "alt" }
local modShift = { "alt", "shift" }

local workspaceCount = 9
local scratchTitle = "scratchterm"
local scratchHeightFraction = 0.45

hs.window.animationDuration = 0

-- macOS itself switches desktops via ctrl+<number>, which is instant and has no
-- Mission Control animation. Synthesising that keystroke is far smoother than
-- hs.spaces.gotoSpace, which has to open Mission Control to work.
local function gotoWorkspace(index)
  hs.eventtap.keyStroke({ "ctrl" }, tostring(index), 0)
end

-- Ordered list of ordinary (non-fullscreen) spaces on the focused screen.
local function userSpaces()
  local screen = hs.screen.mainScreen()
  local spaces = hs.spaces.spacesForScreen(screen)
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

local function moveWindowToWorkspace(index, follow)
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  local spaces = userSpaces()
  local target = spaces[index]
  if not target then
    hs.alert.show("No desktop " .. index)
    return
  end

  local ok, err = hs.spaces.moveWindowToSpace(win, target)
  if not ok then
    hs.alert.show("Move failed: " .. tostring(err))
    return
  end

  if follow then
    gotoWorkspace(index)
    hs.timer.doAfter(0.2, function()
      win:focus()
    end)
  end
end

for index = 1, workspaceCount do
  local key = tostring(index)
  hs.hotkey.bind(mod, key, function()
    gotoWorkspace(index)
  end)
  hs.hotkey.bind(modShift, key, function()
    moveWindowToWorkspace(index, true)
  end)
end

-- Quake-style scratch terminal -----------------------------------------------
--
-- A single kitty instance identified by its window title. It is pulled onto
-- whichever desktop is currently active, so it behaves like Hyprland's special
-- workspace rather than living on one fixed desktop.

local kittyBin = os.getenv("HOME") .. "/.nix-profile/bin/kitty"

local function scratchWindow()
  for _, win in ipairs(hs.window.allWindows()) do
    if win:title() == scratchTitle then
      return win
    end
  end
  return nil
end

local function positionScratch(win)
  local frame = win:screen():frame()
  win:setFrame({
    x = frame.x,
    y = frame.y,
    w = frame.w,
    h = frame.h * scratchHeightFraction,
  })
end

local function spawnScratch()
  hs.task
    .new(kittyBin, nil, {
      "--single-instance",
      "--instance-group",
      "scratch",
      "--title",
      scratchTitle,
    })
    :start()

  -- kitty needs a moment before its window exists.
  hs.timer.waitUntil(scratchWindow, function()
    local win = scratchWindow()
    positionScratch(win)
    win:focus()
  end, 0.1)
end

local function toggleScratch()
  local win = scratchWindow()

  if not win then
    spawnScratch()
    return
  end

  local focused = hs.window.focusedWindow()
  if focused and focused:id() == win:id() then
    win:application():hide()
    return
  end

  local currentSpace = hs.spaces.focusedSpace()
  local windowSpaces = hs.spaces.windowSpaces(win) or {}
  local onCurrentSpace = false
  for _, spaceID in ipairs(windowSpaces) do
    if spaceID == currentSpace then
      onCurrentSpace = true
    end
  end

  if not onCurrentSpace then
    hs.spaces.moveWindowToSpace(win, currentSpace)
  end

  win:application():unhide()
  positionScratch(win)
  win:focus()
end

hs.hotkey.bind(mod, "s", toggleScratch)

-- Reload configuration on demand and whenever this file changes.
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
