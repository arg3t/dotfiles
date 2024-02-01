-- Appearance Settings

-- Set command-line height
vim.opt.cmdheight = 2

-- Tab and indent settings
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- Status line
vim.opt.laststatus = 2

-- Material theme style
vim.opt.termguicolors = true

-- Colorscheme settings
vim.opt.background = "dark"

vim.cmd.colorscheme "catppuccin"
vim.wo.relativenumber = true
vim.wo.number = true

vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h12:#h-slight"
vim.g.neovide_cursor_vfx_mode = "railgun"
