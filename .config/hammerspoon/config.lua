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

  remapKeys = {
    c = "cmd",
    v = "cmd",
    x = "cmd",
    w = "cmd",
    a = "cmd",
    left = "alt",
    right = "alt",
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

  -- cmd acts as alt inside these apps so the alt-based tab bindings are reachable
  -- with the mac modifier. Only the listed keys are rewritten; everything else keeps
  -- its macOS meaning (cmd+c/v/x/s/w/p/tab untouched on purpose).
  -- Shift is preserved: cmd+shift+, -> alt+shift+,
  -- Do NOT add digits, c, s, x, f, q, return or arrows here: `mod` (alt) owns those
  -- globally for workspaces/snapping/apps, so they never reach the app anyway.
  cmdAsAltKeys = {
    ["Cursor"] = {
      [","] = true, -- prev tab   (cmd+shift+, moves tab left)
      ["."] = true, -- next tab   (cmd+shift+. moves tab right)
    },
    ["Zed"] = {
      [","] = true,
      ["."] = true,
    },
  },

  appNameAliases = {
    ["Firefox"] = "firefox",
  },

  mouseTabApps = {
    ["firefox"] = true,
    ["Firefox"] = true,
    ["Google Chrome"] = true,
  },
}

return M
