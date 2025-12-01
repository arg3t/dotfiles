local map = vim.api.nvim_set_keymap

-- == LSP Pickers ==
map('n', '<Leader>ll', "<Cmd> Telescope <CR>", {
  noremap = true,
  desc = "Open main telescope picket"
})

map('n', '<C-p>', "<Cmd> Telescope commands <CR>", {
  noremap = true,
  desc = "Open main telescope picket"
})

map('n', '<Leader><Leader>', "<Cmd>lua vim.lsp.buf.code_action()<CR>", {
  noremap = true,
  desc = "Resume last pick action"
})

map('n', '<Leader>lf', "<Cmd> lua require('telescope.builtin').find_files()<CR>", {
  noremap = true,
  desc = "Open File"
})

map('n', '<Leader>ld', "<Cmd> lua require('telescope.builtin').lsp_definitions()<CR>", {
  noremap = true,
  desc = "Go to definition"
})

map('n', '<Leader>lD', "<Cmd> lua  vim.diagnostic.open_float()<CR>", {
  noremap = true,
  desc = "Show diagnostic float"
})

map('n', '<Leader>lr', "<Cmd> lua require('telescope.builtin').lsp_references()<CR>", {
  noremap = true,
  desc = "List to references to word under cursor"
})

map('n', '<Leader>lR', "<Cmd> lua vim.lsp.buf.rename()<CR>", {
  noremap = true,
  desc = "Rename the word under the cursor"
})

map('n', '<F2>', "<Cmd> lua vim.lsp.buf.rename()<CR>", {
  noremap = true,
  desc = "Rename the word under the cursor"
})

map('n', '<Leader>lt', "<Cmd>lua require('telescope.builtin').treesitter()<CR>", {
  noremap = true,
  desc = "List symbols in workspace with treesitter"
})

map('n', '<Leader>lw', "<Cmd>lua require('telescope.builtin').diagnostics()<CR>", {
  noremap = true,
  desc = "List diagnostic items"
})

map('n', '<Leader>lm', "<Cmd>lua require('telescope.builtin').man_pages()<CR>", {
  noremap = true,
  desc = "List view manpage"
})

map('n', '<Leader><Space>', "<Cmd>lua vim.lsp.buf.code_action()<CR>", {
  noremap = true,
  desc = "Pick code action"
})

map("v", "<Leader><Space>", "<Cmd>'<,'>lua vim.lsp.buf.code_action()<CR>", {
  noremap = true,
  desc = "Pick code action for selection"
})

map('n', '<Leader>ls', "<Cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>", {
  noremap = true,
  desc = "Lsp symbols"
})

map('n', '<Leader>lg', "<Cmd>lua require('telescope.builtin').live_grep()<CR>", {
  noremap = true,
  desc = "Live search"
})

-- == Misc Keybinds ==
map('n', '<Leader>b', "<Cmd>lua require('telescope.builtin').buffers()<CR>", {
  noremap = true,
  desc = "List and pick buffers"
})


map('n', '<Leader>S', "<Cmd>SessionSearch<CR>", {
  noremap = true,
  desc = "Select a session"
})
