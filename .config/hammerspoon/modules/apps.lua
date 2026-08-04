local config = require("config")

local M = {}

function M.start()
  hs.hotkey.bind(config.mod, "x", function()
    hs.caffeinate.lockScreen()
  end)

  -- Open a normal Ghostty window (OmniWM tiles it). The quake/scratch terminal
  -- is OmniWM's own Option+` toggle, so the old kitty quick-access bind is gone.
  hs.hotkey.bind(config.mod, "return", function()
    hs.task.new("/usr/bin/open", nil, { "-a", "Ghostty" }):start()
  end)
end

return M
