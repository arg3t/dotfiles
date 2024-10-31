local M = { "nvim-neotest/neotest" }
M.dependencies = {
  "nvim-lua/plenary.nvim",
  "nvim-treesitter/nvim-treesitter",
  "antoinemadec/FixCursorHold.nvim",
  "nvim-neotest/nvim-nio",
  "nvim-neotest/neotest-python",
}

M.config = function()
  require("neotest").setup({
    adapters = {
      require("neotest-python")
    }
  })
end

return M
