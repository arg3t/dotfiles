local M = {"romgrk/barbar.nvim"}
M.dependencies = {
"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
}
M.init = function()
vim.g.barbar_auto_setup = false
end

M.opts = {}
M.version = "^1.0.0" -- optional: only update when a new 1.x version is released

return M



