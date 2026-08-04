local config = require("config")
local keyboard = require("modules.keyboard")

local M = {}

local function describe(app)
  if not app then
    return "?"
  end
  local bundle = app.bundleID and app:bundleID() or "?"
  return (app:name() or "?") .. " [" .. (bundle or "?") .. "]"
end

function M.start()
  -- OmniWM has its own workspace bar, so Hammerspoon keeps only the app-info
  -- toast and config auto-reload. (No manual reload hotkey: alt+shift+r collides
  -- with OmniWM's "Raise All Floating Windows", and saving a .lua auto-reloads.)
  hs.hotkey.bind(config.modShift, "d", function()
    local frontmost = hs.application.frontmostApplication()
    local win = hs.window.focusedWindow()
    hs.alert.show(
      "frontmost: " .. describe(frontmost)
      .. "  |  focused-win: " .. describe(win and win:application())
      .. "  |  terminal? " .. tostring(keyboard.isTerminalFocused())
    )
  end)

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

  hs.alert.show("Hammerspoon loaded")
end

return M
