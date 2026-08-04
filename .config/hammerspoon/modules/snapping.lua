local config = require("config")

local M = {}

local function snap(shape)
  return function()
    local win = hs.window.focusedWindow()
    if not win then
      return
    end

    local app = win:application()
    if app and config.noSnapApps[app:name()] then
      return
    end

    local f = win:screen():frame()
    win:setFrame(shape(f))
  end
end

function M.start()
  hs.hotkey.bind(config.mod, "f", snap(function(f)
    return f
  end))

  hs.hotkey.bind(config.mod, "left", snap(function(f)
    return { x = f.x, y = f.y, w = f.w / 2, h = f.h }
  end))

  hs.hotkey.bind(config.mod, "right", snap(function(f)
    return { x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h }
  end))

  hs.hotkey.bind(config.mod, "up", snap(function(f)
    return { x = f.x, y = f.y, w = f.w, h = f.h / 2 }
  end))

  hs.hotkey.bind(config.mod, "down", snap(function(f)
    return { x = f.x, y = f.y + f.h / 2, w = f.w, h = f.h / 2 }
  end))

  hs.hotkey.bind(config.mod, "q", function()
    local win = hs.window.focusedWindow()
    if win then
      win:close()
    end
  end)
end

return M
