-- Enable syntax highlighting
vim.opt.syntax = "on"

-- Autocomplete settings in command mode
vim.opt.wildmenu = true
vim.opt.wildmode = "longest,list,full"

-- Various settings
vim.opt.autoread = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.lazyredraw = false
vim.opt.ttyfast = true

vim.opt.wrap = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.errorbells = false
vim.opt.visualbell = false
vim.opt.history = 500
vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.showcmd = true
vim.cmd('nohlsearch')

vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 10

vim.opt.shortmess:append("c")
vim.opt.updatetime = 300

-- Persistent undo settings
vim.opt.undodir = vim.fn.expand('~/.local/share/vim/undo/')
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

-- Wildignore settings
vim.opt.wildignore:append({ "*/tmp/*", "*.so", "*.zip", "*/vendor/bundle/*", "*/node_modules/" })

-- Autocommand to disable auto commenting on new lines
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove("c")
    vim.opt_local.formatoptions:remove("r")
    vim.opt_local.formatoptions:remove("o")
  end
})

-- Set minimum yank message length to
vim.opt.report = 10

-- Filetype settings
vim.cmd('filetype off')
vim.cmd('filetype plugin on')

-- Autocomplete settings
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Folding settings
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
