-- Set copilot_no_tab_map to true
vim.g.copilot_no_tab_map = true

-- Map <C-J> in insert mode to copilot#Accept("<CR>")
vim.api.nvim_set_keymap('i', '<C-J>', 'v:lua.copilot_accept()', { silent = true, expr = true })

-- Function to handle copilot#Accept("<CR>")
function copilot_accept()
    return vim.fn["copilot#Accept"]("<CR>")
end

-- Disable copilot for certain filetypes
vim.g.copilot_filetypes = {
    ["*"] = false,
    ["javascript"] = true,
    ["typescript"] = true,
    ["lua"] = false,
    ["rust"] = true,
    ["c"] = true,
    ["c#"] = true,
    ["c++"] = true,
    ["go"] = true,
    ["python"] = true,
}
