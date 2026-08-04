local config = require("config")
local spaces = require("modules.spaces")
local apps = require("modules.apps")
local keyboard = require("modules.keyboard")

local M = {}

local desktopIndicator

local function refreshIndicator()
  if not desktopIndicator then
    return
  end

  local targets = spaces.targets()
  local current = spaces.indexForSpace(targets, hs.spaces.focusedSpace())

  desktopIndicator:setTitle("D" .. (current or "?"))

  local menu = {}
  for _, target in ipairs(targets) do
    table.insert(menu, {
      title = "Desktop " .. target.aliasIndex .. " (Option+" .. target.key .. ")",
      checked = target.aliasIndex == current,
      fn = function()
        spaces.gotoWorkspace(target.key)
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

  local spaceWatcher = hs.spaces.watcher.new(function()
    apps.run("set-darwin-background", { "--reapply" })
    refreshIndicator()
  end)
  spaceWatcher:start()
  M.spaceWatcher = spaceWatcher

  local screenWatcher = hs.screen.watcher.newWithActiveScreen(function(activeScreenChanged)
    spaces.onScreenChange(activeScreenChanged)
    refreshIndicator()
  end)
  screenWatcher:start()
  M.screenWatcher = screenWatcher

  hs.hotkey.bind(config.modShift, "i", function()
    local targets = spaces.targets()
    local current = spaces.indexForSpace(targets, hs.spaces.focusedSpace())
    hs.alert.show(("desktop %s of %d"):format(current or "?", spaces.aliasCount(targets)))
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
