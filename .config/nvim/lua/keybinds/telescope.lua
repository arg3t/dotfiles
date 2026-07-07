local map = vim.keymap.set

-- ============================================================================
-- Telescope: entry points / general pickers
-- ============================================================================
map('n', '<Leader>ll', '<Cmd>Telescope<CR>', {
  noremap = true,
  desc = 'Telescope: builtins (main picker)',
})

map('n', '<C-p>', '<Cmd>Telescope commands<CR>', {
  noremap = true,
  desc = 'Telescope: commands',
})

map('n', '<Leader>lf', function()
  require('telescope.builtin').find_files()
end, {
  noremap = true,
  desc = 'Telescope: find files',
})

map('n', '<Leader>b', function()
  require('telescope.builtin').buffers()
end, {
  noremap = true,
  desc = 'Telescope: buffers',
})

map('n', '<Leader>lg', function()
  require('telescope.builtin').live_grep()
end, {
  noremap = true,
  desc = 'Telescope: live grep',
})

-- ============================================================================
-- LSP: navigation / symbols / references (via Telescope)
-- ============================================================================
map('n', '<Leader>ld', function()
  require('telescope.builtin').lsp_definitions()
end, {
  noremap = true,
  desc = 'LSP: go to definition (Telescope)',
})

map('n', '<Leader>lr', function()
  require('telescope.builtin').lsp_references()
end, {
  noremap = true,
  desc = 'LSP: references (Telescope)',
})

map('n', '<Leader>ls', function()
  require('telescope.builtin').lsp_dynamic_workspace_symbols()
end, {
  noremap = true,
  desc = 'LSP: workspace symbols (Telescope)',
})

map('n', '<Leader>lt', function()
  require('telescope.builtin').treesitter()
end, {
  noremap = true,
  desc = 'Symbols: treesitter (Telescope)',
})

-- ============================================================================
-- LSP: actions / diagnostics
-- ============================================================================
map('n', '<Leader><Leader>', vim.lsp.buf.code_action, {
  noremap = true,
  desc = 'LSP: code actions',
})

map('n', '<Leader><Space>', vim.lsp.buf.code_action, {
  noremap = true,
  desc = 'LSP: code actions',
})

map('v', '<Leader><Space>', vim.lsp.buf.code_action, {
  noremap = true,
  desc = 'LSP: code actions (selection)',
})

map('n', '<F2>', vim.lsp.buf.rename, {
  noremap = true,
  desc = 'LSP: rename symbol',
})

map('n', '<Leader>lD', vim.diagnostic.open_float, {
  noremap = true,
  desc = 'Diagnostics: float under cursor',
})

map('n', '<Leader>lw', function()
  require('telescope.builtin').diagnostics()
end, {
  noremap = true,
  desc = 'Diagnostics: list (Telescope)',
})

-- ============================================================================
-- Docs / help
-- ============================================================================
map('n', '<Leader>lm', function()
  require('telescope.builtin').man_pages()
end, {
  noremap = true,
  desc = 'Man pages (Telescope)',
})

-- ============================================================================
-- Sessions
-- ============================================================================
map('n', '<Leader>S', '<Cmd>SessionSearch<CR>', {
  noremap = true,
  desc = 'Sessions: search/select',
})

-- ============================================================================
-- Telescope -> Quickfix (results export)
-- ============================================================================
-- Inside ANY Telescope picker:
--   <C-q>  sends the entire current results list to quickfix (+ opens it)
--   <M-q>  sends only the selected entries to quickfix (+ opens it)
--
-- These are Telescope default mappings. If you want them ALWAYS available
-- (even if you override Telescope mappings elsewhere), add them in your
-- telescope.setup({ defaults = { mappings = ... } }) config. :contentReference[oaicite:1]{index=1}
