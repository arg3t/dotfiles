local M = {
  mod = { "alt" },
  modShift = { "alt", "shift" },

  terminalBundles = {
    ["com.mitchellh.ghostty"] = true,
    ["com.barut.OmniWM"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true,
    ["com.github.wez.wezterm"] = true,
    ["org.alacritty"] = true,
  },

  terminalApps = {
    ["Ghostty"] = true,
    ["ghostty"] = true,
    ["Terminal"] = true,
    ["iTerm2"] = true,
    ["WezTerm"] = true,
    ["Alacritty"] = true,
  },

  -- ctrl+<key> is delivered as <modifier>+<key> everywhere except terminals.
  remapKeys = {
    c = "cmd",
    v = "cmd",
    x = "cmd",
    w = "cmd",
    a = "cmd",
    -- No left/right here: alt+arrow is OmniWM's focus hotkey, so rewriting
    -- ctrl+arrow onto it would move window focus instead of the cursor.
    -- ctrl+arrow word motion is bound natively in Cursor and Zed instead.
    -- backspace: macOS spells delete-word-backward as alt+delete, so this is what
    -- makes ctrl+backspace delete a word in Cursor, Zed and the browsers alike.
    delete = "alt",
  },

  appKeyRemaps = {
    ["firefox"] = {
      { from = { {}, "f" },         to = { { "cmd" }, "f" } },
      { from = { { "ctrl" }, "-" }, to = { { "cmd" }, "-" } },
      { from = { { "ctrl" }, "=" }, to = { { "cmd" }, "=" } },
    },
    ["Google Chrome"] = {
      { from = { {}, "f" },         to = { { "cmd" }, "f" } },
      { from = { { "ctrl" }, "-" }, to = { { "cmd" }, "-" } },
      { from = { { "ctrl" }, "=" }, to = { { "cmd" }, "=" } },
    },
    ["Slack"] = {
      { from = { { "ctrl" }, "k" }, to = { { "cmd" }, "k" } },
    },
    ["Zed"] = {
      { from = { {}, "p" },          to = { { "cmd" }, "p" } },
      { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
    },
    ["Cursor"] = {
      { from = { {}, "p" },          to = { { "cmd" }, "p" } },
      { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
    },
  },

  -- Inside these apps cmd is delivered as another modifier, so the app's existing
  -- alt/ctrl bindings are reachable with the mac modifier. Only the listed keys are
  -- rewritten; everything else keeps its macOS meaning (cmd+c/v/x/s/w/p/tab untouched).
  -- Shift is preserved: cmd+shift+, -> alt+shift+,
  -- Do NOT map to "alt" the keys OmniWM owns globally (digits, arrows, return, and
  -- its Option chords) or the app never sees them.
  cmdRemapKeys = {
    ["Cursor"] = {
      [","] = "alt", -- prev tab (cmd+shift+, moves tab left)
      ["."] = "alt", -- next tab (cmd+shift+. moves tab right)
      -- Only h: macOS eats cmd+h (Hide App) before any app sees it, so it is
      -- rewritten onto the ctrl+h split-nav binding both editors already have.
      -- cmd+j/k/l are bound natively in each editor instead — as ctrl they would
      -- insert junk in vim insert mode.
      h = "ctrl",
    },
    ["Zed"] = {
      [","] = "alt",
      ["."] = "alt",
      h = "ctrl",
    },
  },

  appNameAliases = {
    ["Firefox"] = "firefox",
  },

  -- ctrl+click behaves as cmd+click: browser tabs, and goto-definition/open-to-the-side
  -- in the editors, which normalize their "goto" modifier to cmd on macOS.
  -- "all" also rewrites ctrl+scroll (editor zoom); "click" leaves scroll alone so the
  -- macOS scroll-to-zoom accessibility gesture still works in browsers.
  ctrlMouseAsCmdApps = {
    ["firefox"] = "click",
    ["Google Chrome"] = "click",
    ["Cursor"] = "all",
    ["Zed"] = "all",
  },
}

return M
