local M = {
  mod = { "alt" },
  modShift = { "alt", "shift" },

  builtInWorkspaceCount = 4,
  peripheralWorkspaceCount = 3,

  desktopMapping = {
    { key = "1", monitor = "peripheral", index = 1, space = 1 },
    { key = "2", monitor = "peripheral", index = 2, space = 1 },
    { key = "3", monitor = "builtin", space = 1 },
    { key = "4", monitor = "peripheral", index = 1, space = 2 },
    { key = "5", monitor = "peripheral", index = 1, space = 3 },
    { key = "6", monitor = "peripheral", index = 2, space = 2 },
    { key = "7", monitor = "peripheral", index = 2, space = 3 },
    { key = "8", monitor = "builtin", space = 2 },
    { key = "9", monitor = "builtin", space = 3 },
    { key = "0", monitor = "builtin", space = 4 },
  },

  noSnapApps = {
    ["SuperCmd"] = true,
  },

  terminalBundles = {
    ["net.kovidgoyal.kitty"] = true,
    ["net.kovidgoyal.kitty-quick-access"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true,
    ["com.github.wez.wezterm"] = true,
    ["org.alacritty"] = true,
  },

  terminalApps = {
    ["kitty"] = true,
    ["kitty-quick-access"] = true,
    [".kitty-wrapped"] = true,
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
    -- No left/right here: alt+arrow is PaperWM's focus hotkey (modules/tiling.lua),
    -- so rewriting ctrl+arrow onto it moves window focus instead of the cursor.
    -- ctrl+arrow word motion is bound natively in Cursor and Zed instead.
    -- backspace: macOS spells delete-word-backward as alt+delete, so this is what
    -- makes ctrl+backspace delete a word in Cursor, Zed and the browsers alike.
    delete = "alt",
  },

  appKeyRemaps = {
    ["firefox"] = {
      { from = { {}, "f" }, to = { { "cmd" }, "f" } },
    },
    ["Google Chrome"] = {
      { from = { {}, "f" }, to = { { "cmd" }, "f" } },
    },
    ["Zed"] = {
      { from = { {}, "p" }, to = { { "cmd" }, "p" } },
      { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
    },
    ["Cursor"] = {
      { from = { {}, "p" }, to = { { "cmd" }, "p" } },
      { from = { { "shift" }, "p" }, to = { { "cmd", "shift" }, "p" } },
    },
  },

  -- Inside these apps cmd is delivered as another modifier, so the app's existing
  -- alt/ctrl bindings are reachable with the mac modifier. Only the listed keys are
  -- rewritten; everything else keeps its macOS meaning (cmd+c/v/x/s/w/p/tab untouched).
  -- Shift is preserved: cmd+shift+, -> alt+shift+,
  -- Do NOT map digits, c, s, x, f, q, return or arrows to "alt": `mod` (alt) owns
  -- those globally for workspaces/tiling/apps, so they never reach the app anyway.
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
