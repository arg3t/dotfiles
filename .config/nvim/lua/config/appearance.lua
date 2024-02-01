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

if vim.fn.hostname() == "tarnag" then
  -- Desktop needs different font
  vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h12:#h-slight"
else
  vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h8:#h-slight"
end

vim.g.neovide_cursor_vfx_mode = "railgun"
