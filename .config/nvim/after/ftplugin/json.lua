local ext = vim.fn.expand("%:e")
if ext == "jsonl" then
  vim.opt_local.wrap = false
  vim.opt_local.linebreak = false
  return
end

-- Enable wrap and linebreak for JSON files
vim.opt_local.wrap = true
vim.opt_local.linebreak = true

-- Make j and k navigate by display lines (wrapped lines)
vim.keymap.set('n', 'j', 'gj', { buffer = true, noremap = true, silent = true })
vim.keymap.set('n', 'k', 'gk', { buffer = true, noremap = true, silent = true })
