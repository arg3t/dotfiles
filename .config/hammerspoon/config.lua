local M = {
  mod = { "alt" },
  modShift = { "alt", "shift" },

  terminalBundles = {
    ["com.mitchellh.ghostty"] = true,
    ["so.stencil.tern"] = true,
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
      -- Keep Ctrl+1..9 unchanged; every other entry mirrors Chrome's Linux shortcut.
      { from = { {}, "f" },         to = { { "cmd" }, "f" } },
      { from = { { "ctrl" }, "-" }, to = { { "cmd" }, "-" } },
      { from = { { "ctrl" }, "=" }, to = { { "cmd" }, "=" } },
      { from = { {}, "0" },         to = { { "cmd" }, "0" } },
      { from = { {}, "l" },         to = { { "cmd" }, "l" } },
      { from = { {}, "r" },         to = { { "cmd" }, "r" } },
      { from = { { "shift" }, "r" }, to = { { "cmd", "shift" }, "r" } },
      { from = { {}, "t" },         to = { { "cmd" }, "t" } },
      { from = { { "shift" }, "t" }, to = { { "cmd", "shift" }, "t" } },
      { from = { {}, "tab" },       to = { { "cmd", "alt" }, "right" } },
      { from = { { "shift" }, "tab" }, to = { { "cmd", "alt" }, "left" } },
      { from = { {}, "d" },         to = { { "cmd" }, "d" } },
      { from = { {}, "h" },         to = { { "cmd" }, "y" } },
      { from = { {}, "j" },         to = { { "cmd", "shift" }, "j" } },
      { from = { { "shift" }, "n" }, to = { { "cmd", "shift" }, "n" } },
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

  -- Cursor and Zed remap selected Cmd keys onto existing Alt/Ctrl bindings.
  -- Other Cmd shortcuts stay native in those editors; Shift is preserved.
  -- Do not map to Option keys that OmniWM owns globally.
  cmdRemapKeys = {
    -- macOS handles these keys before Tern's keymap. Use unused chords so Tern
    -- can choose terminal bytes or text editing based on the focused view.
    ["Tern"] = {
      a = { "ctrl", "alt", "shift" },
      c = { "ctrl", "alt", "shift" },
      -- ponytail: Cmd+H/M skip Hide/Minimize in file views; add focus-aware routing if needed.
      h = { "ctrl", "alt", "shift" },
      m = { "ctrl", "alt", "shift" },
      v = { "ctrl", "alt", "shift" },
      x = { "ctrl", "alt", "shift" },
      q = { "ctrl", "alt", "shift" },
      [","] = { "ctrl", "alt", "shift" },
    },
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
