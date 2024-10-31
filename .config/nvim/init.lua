-- Set leader key
vim.g.mapleader = ','
vim.g.maplocalleader = "\\"

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Initialize Config
require('config')

-- Initialize Keybinds
require('keybinds')

-- Initialize LSP
require('lsp')

-- Initialize AutoCmds
require('autocmd')
