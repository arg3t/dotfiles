local M = { "rest-nvim/rest.nvim" }
M.dependencies = { { "nvim-lua/plenary.nvim" } }
M.config = function()
require("rest-nvim").setup({})
end

return M
