local mod = { "alt" }
local modShift = { "alt", "shift" }

local workspaceCount = 9

hs.window.animationDuration = 0

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

  hs.eventtap.keyStroke({ "ctrl" }, tostring(index), 0)

  -- Falls back to the API when the native ctrl+<n> shortcut is disabled.
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

local function run(name, args)
  local bin = binPath(name)
  if not bin then
    hs.alert.show(name .. " not found")
    return
  end
  hs.task.new(bin, nil, args):start()
end

hs.hotkey.bind(mod, "s", function()
  run("kitten", { "quick-access-terminal" })
end)

hs.hotkey.bind(mod, "return", function()
  run("kitty", { "--single-instance" })
  hs.timer.doAfter(0.3, function()
    local app = hs.application.get("kitty")
    if app then
      app:activate()
    end
  end)
end)

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
