local config = require("config")
local keyboard = require("modules.keyboard")

local M = {}

local desktopIndicator

-- Resolve the aerospace CLI (installed by the services.aerospace module).
local function aerospaceBin()
  local candidates = {
    "/run/current-system/sw/bin/aerospace",
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/aerospace",
    (os.getenv("HOME") or "") .. "/.nix-profile/bin/aerospace",
    "/opt/homebrew/bin/aerospace",
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return nil
end

local function aerospace(args)
  local bin = aerospaceBin()
  if not bin then
    return nil
  end
  return hs.execute(bin .. " " .. args)
end

local function focusedWorkspace()
  local out = aerospace("list-workspaces --focused")
  if not out then
    return nil
  end
  return (out:gsub("%s+$", ""))
end

local function allWorkspaces()
  local out = aerospace("list-workspaces --all") or ""
  local result = {}
  for line in out:gmatch("[^\n]+") do
    local name = line:gsub("%s+$", "")
    if #name > 0 then
      table.insert(result, name)
    end
  end
  return result
end

local function refreshIndicator()
  if not desktopIndicator then
    return
  end

  local current = focusedWorkspace()
  desktopIndicator:setTitle("D" .. (current or "?"))

  local menu = {}
  for _, name in ipairs(allWorkspaces()) do
    table.insert(menu, {
      title = "Workspace " .. name,
      checked = name == current,
      fn = function()
        aerospace("workspace " .. name)
        refreshIndicator()
      end,
    })
  end
  desktopIndicator:setMenu(menu)
end

local function describe(app)
  if not app then
    return "?"
  end
  local bundle = app.bundleID and app:bundleID() or "?"
  return (app:name() or "?") .. " [" .. (bundle or "?") .. "]"
end

function M.start()
  desktopIndicator = hs.menubar.new(true, "hammerspoonDesktops")
  M.desktopIndicator = desktopIndicator

  -- AeroSpace does not push workspace changes into Hammerspoon, so poll the CLI
  -- to keep the menubar indicator current.
  local indicatorTimer = hs.timer.doEvery(1, refreshIndicator)
  M.indicatorTimer = indicatorTimer

  hs.hotkey.bind(config.modShift, "i", function()
    hs.alert.show("workspace " .. (focusedWorkspace() or "?"))
  end)

  hs.hotkey.bind(config.modShift, "d", function()
    local frontmost = hs.application.frontmostApplication()
    local win = hs.window.focusedWindow()
    hs.alert.show(
      "frontmost: " .. describe(frontmost)
      .. "  |  focused-win: " .. describe(win and win:application())
      .. "  |  terminal? " .. tostring(keyboard.isTerminalFocused())
    )
  end)

  hs.hotkey.bind(config.modShift, "r", hs.reload)

  local configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
    for _, file in ipairs(files) do
      if file:sub(-4) == ".lua" then
        hs.reload()
        return
      end
    end
  end)
  configWatcher:start()
  M.configWatcher = configWatcher

  refreshIndicator()
  hs.alert.show("Hammerspoon loaded")
end

return M
