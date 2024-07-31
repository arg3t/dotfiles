local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

vim.api.nvim_create_autocmd(
  "BufWritePre",
  {
    pattern = "*.lua",
    group = "AutoFormat",
    callback = function()
      vim.lsp.buf.format {}
    end,
  }
)
