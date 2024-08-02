local M = { "folke/which-key.nvim" }
M.event = "VeryLazy"
M.init = function()
  vim.o.timeout = true
  vim.o.timeoutlen = 300
end

M.config = function()
  local settings = {
    spec = {
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lsp" },
      { "<leader>s", group = "search" },
    }
  }
  require("which-key").setup(settings)
end

return M
