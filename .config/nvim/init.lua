-- Set leader key
vim.g.mapleader = ','
vim.g.maplocalleader = "\\"

-- Initialize Config
require('config')

-- Initialize Keybinds
require('keybinds')

-- Initialize LSP
require('lsp')

-- Initialize AutoCmds
require('autocmd')

