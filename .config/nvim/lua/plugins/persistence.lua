local M = {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    pre_save = function() vim.api.nvim_exec_autocmds('User', { pattern = 'SessionSavePre' }) end,
  }
}

return M
