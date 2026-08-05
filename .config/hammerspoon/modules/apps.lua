local config = require("config")

local M = {}

local omniwmctl = "/run/current-system/sw/bin/omniwmctl"

function M.start()
  hs.hotkey.bind(config.mod, "x", function()
    hs.caffeinate.lockScreen()
  end)

  -- Close the focused window. OmniWM has no close-window action of its own, so
  -- Hammerspoon keeps this (matches the old snapping.lua alt+q).
  hs.hotkey.bind(config.mod, "q", function()
    local win = hs.window.focusedWindow()
    if win then
      win:close()
    end
  end)

  -- Open a new Ghostty window. `-n` forces a new window even when Ghostty is
  -- already running. The scratch/quake terminal is OmniWM's Option+S toggle.
  hs.hotkey.bind(config.mod, "return", function()
    hs.task.new("/usr/bin/open", nil, { "-na", "Ghostty" }):start()
  end)

  -- OmniWM only binds direct workspace hotkeys for 1-9; workspace 10 is reachable
  -- only via IPC. Drive omniwmctl for Option+0 (switch) and Option+Shift+0 (move
  -- the focused window there).
  hs.hotkey.bind(config.mod, "0", function()
    hs.task.new(omniwmctl, nil, { "command", "switch-workspace", "10" }):start()
  end)
  hs.hotkey.bind(config.modShift, "0", function()
    hs.task.new(omniwmctl, nil, { "command", "move-to-workspace", "10" }):start()
  end)
end

return M
