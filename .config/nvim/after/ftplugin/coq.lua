local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- only set keybindings if filetype is coq
if vim.bo.filetype == 'coq' then
  vim.keymap.set({ 'n', 'i' }, '<M-Down>', '<Cmd>CoqNext<CR>', { buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<M-Up>', '<Cmd>CoqUndo<CR>', { buffer = bufnr })
  -- Run CoqToLine to the current line
  vim.keymap.set({ 'n', 'i' }, '<M-Right>', function()
    local current_line = vim.fn.line('.')
    vim.cmd('CoqToLine ' .. current_line)
  end, { buffer = bufnr })
end
