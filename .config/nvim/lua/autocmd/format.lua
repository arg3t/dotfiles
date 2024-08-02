vim.api.nvim_create_augroup("AutoFormat", {})

vim.api.nvim_create_autocmd(
  "BufWritePost",
  {
    pattern = "*",
    group = "AutoFormat",
    callback = function()
      MiniTrailspace.trim()
      MiniTrailspace.trim_last_lines()
    end,
  }
)
