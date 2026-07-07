vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'py', 'python', 'cpp', 'c', 'lua', 'rust', 'go', 'typst', 'javascript', 'typescript', 'nu' },
  callback = function() vim.treesitter.start() end,
})
