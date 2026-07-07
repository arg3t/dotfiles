local M = { "romgrk/barbar.nvim" }
M.dependencies = {
  "lewis6991/gitsigns.nvim",
  "nvim-tree/nvim-web-devicons",
}
M.init = function()
  vim.g.barbar_auto_setup = false
end

M.opts = {}

return M
