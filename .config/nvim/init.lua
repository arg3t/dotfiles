-- Source the plug.vim plugin
vim.cmd('source ~/.config/nvim/colors/material.vim')
vim.cmd('source ~/.vimrc')

-- Load plugins
require('plugin.init')

-- Initialize Keybinds
require('config.init')

-- Initialize LSP
require('lsp.init')

-- Initialize Keybinds
require('keybinds.init')

