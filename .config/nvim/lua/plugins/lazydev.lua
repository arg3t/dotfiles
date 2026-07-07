local M = { "folke/lazydev.nvim" }
M.ft = "lua"
M.opts = {
  library = {
    { path = "nvim-dap-ui", words = { "dapui" } },
  },
}

return M
