local map = vim.api.nvim_set_keymap
local opts = {noremap = true}

-- [,w] SAVE
map('', '<Leader>w', ':update<CR>', opts)

-- <VISUAL> [Q] REFORMAT TEXT
map('v', 'Q', 'gq', opts)

-- Clipboard Bindings, Prefixing with leader copies to global
map('n', '<Leader>y', '"+y', opts)
map('n', '<Leader>p', '"+p', opts)
map('v', '<Leader>y', '"+y', opts)
map('v', '<Leader>p', '"+p', opts)
map('n', '<Leader>Y', '"+Y', opts)
map('n', '<Leader>P', '"+P', opts)
map('v', '<Leader>d', '"+d', opts)
map('n', '<Leader>D', '"+D', opts)

-- Find and replace with Ctrl-R
map('v', '<C-r>', '"hy:%s/<C-r>h//g<left><left><left>', opts)

-- Apply . to all selected lines
map('v', '.', ':normal .<CR>', opts)


-- Quit window 
map('', '<Leader>qb', ':q<CR>', opts)

-- Quit all without saving
map('', '<Leader>qq', ':qa!<CR>', opts)

-- Quit with escape from man pages
vim.api.nvim_create_autocmd("FileType", {
    pattern = "man",
    command = "nnoremap <buffer> <Esc> :AerialClose<CR>:bd<CR>"
})
