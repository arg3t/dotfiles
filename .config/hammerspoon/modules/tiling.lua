local config = require("config")

local M = {}

function M.start()
  local PaperWM = hs.loadSpoon("PaperWM")

  -- Gaps between windows and screen edges. init.lua already sets
  -- hs.window.animationDuration = 0, which PaperWM needs for snappy tiling.
  PaperWM.window_gap = 8
  PaperWM.screen_margin = 8

  -- spaces.lua owns cursor placement on Space switches, so stop PaperWM from
  -- also moving the cursor and fighting it.
  PaperWM.center_mouse = false

  -- Exclude the same apps the old snapping layer skipped (config.noSnapApps),
  -- so launchers/overlays stay floating instead of getting tiled.
  for appName in pairs(config.noSnapApps) do
    PaperWM.window_filter:rejectApp(appName)
  end

  -- Intra-Space tiling only. Space navigation and cross-Space window moves stay
  -- owned by modules/spaces.lua, so PaperWM's switch_space_*/move_window_* are
  -- intentionally left unbound: its hs.spaces move path is the same one
  -- spaces.lua deliberately avoids.
  PaperWM:bindHotkeys({
    -- Move focus through the tiled row/column.
    focus_left = { config.mod, "left" },
    focus_right = { config.mod, "right" },
    focus_up = { config.mod, "up" },
    focus_down = { config.mod, "down" },

    -- Reorder the focused window within the layout.
    swap_left = { config.modShift, "left" },
    swap_right = { config.modShift, "right" },
    swap_up = { config.modShift, "up" },
    swap_down = { config.modShift, "down" },

    -- Size and position the focused window (alt+f keeps the old maximize feel).
    full_width = { config.mod, "f" },
    center_window = { config.mod, "c" },
    cycle_width = { config.mod, "r" },
    increase_width = { config.mod, "l" },
    decrease_width = { config.mod, "h" },

    -- Stack the focused window into a column / pull it back out.
    slurp_in = { config.mod, "i" },
    barf_out = { config.mod, "o" },

    -- Float toggle and a way to reach floating windows.
    toggle_floating = { config.modShift, "f" },
    focus_floating = { config.mod, "g" },
  })

  PaperWM:start()

  -- PaperWM has no close action, so keep the old alt+q close-window binding.
  hs.hotkey.bind(config.mod, "q", function()
    local win = hs.window.focusedWindow()
    if win then
      win:close()
    end
  end)

  M.PaperWM = PaperWM
end

return M
