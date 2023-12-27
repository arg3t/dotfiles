local map = vim.api.nvim_set_keymap

-- Toggle breakpoint with F11
vim.api.nvim_set_keymap('n', '<F11>', "<cmd>lua require'dap'.toggle_breakpoint()<CR>", {noremap = true, silent = true})

-- Start debugging with F4
vim.api.nvim_set_keymap('n', '<F4>', "<cmd>lua require'dap'.continue()<CR>", {noremap = true, silent = true})

-- Step into with F7
vim.api.nvim_set_keymap('n', '<F7>', "<cmd>lua require'dap'.step_into()<CR>", {noremap = true, silent = true})

-- Step over with F8
vim.api.nvim_set_keymap('n', '<F8>', "<cmd>lua require'dap'.step_over()<CR>", {noremap = true, silent = true})
