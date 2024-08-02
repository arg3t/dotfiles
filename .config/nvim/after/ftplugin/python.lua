local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- map('n', '<leader>F', '<Cmd>echo 1<CR>', opts)


vim.api.nvim_create_autocmd(
  "BufWritePre",
  {
    pattern = "*.py",
    group = "AutoFormat",
    callback = function()
      vim.lsp.buf.format {}
    end,
  }
)
