local M = { "romgrk/barbar.nvim" }
M.dependencies = {
  "lewis6991/gitsigns.nvim",   -- OPTIONAL: for git status
  "nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
}
M.init = function()
  vim.g.barbar_auto_setup = false
end

M.opts = {}

return M
