vim.g.barbar_auto_setup = false -- disable auto-setup

return {
  auto_hide = 1,
  clickable = true,

  focus_on_close = 'previous',

  icons = {
    button = '',
    -- Enables / disables diagnostic symbols
    diagnostics = {
      [vim.diagnostic.severity.ERROR] = {enabled = true, icon = ''},
      [vim.diagnostic.severity.WARN] = {enabled = false},
      [vim.diagnostic.severity.INFO] = {enabled = false},
      [vim.diagnostic.severity.HINT] = {enabled = true},
    },
    gitsigns = {
      added = {enabled = true, icon = '+'},
      changed = {enabled = true, icon = '~'},
      deleted = {enabled = true, icon = '-'},
    },

    modified = {button = '●'},
    pinned = {button = '', filename = true},
  },

  -- Set the filetypes which barbar will offset itself for
  sidebar_filetypes = {
    NvimTree = true,
  },
}
