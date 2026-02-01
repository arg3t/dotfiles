local M = { "nvim-treesitter/nvim-treesitter" }
M.dependencies = {
  "neovim/nvim-lspconfig",
}
M.build = ":TSUpdate"
M.lazy = false
M.config = function()
  local ts = require("nvim-treesitter")
  ts.setup {}

  ts.install { "html", "json", "regex", "c", "cpp", "css", "bash", "lua", "java", "python", "javascript", "typescript", "latex", "markdown", "markdown_inline", "vim", "regex", "go", "rust", "typst" }
end

return M
