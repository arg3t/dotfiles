local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- map('n', '<leader>F', '<Cmd>echo 1<CR>', opts)

vim.api.nvim_create_autocmd(
  "BufWritePost",
  {
    pattern = "*.py",
    group = "AutoFormat",
    callback = function()
      vim.cmd("silent !black --quiet %")
      vim.cmd("edit")
    end,
  }
)
