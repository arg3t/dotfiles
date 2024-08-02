local M = { "ThePrimeagen/harpoon" }
M.branch = "harpoon2"
M.dependencies = {
  "nvim-lua/plenary.nvim",
}
M.config = function()
  local harpoon = require('harpoon')
  harpoon:setup({})
end
return M
