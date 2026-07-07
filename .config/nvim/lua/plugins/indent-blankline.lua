local M = { "lukas-reineke/indent-blankline.nvim" }
M.main = "ibl"
M.opts = {
  exclude = {
    filetypes = {
      "dashboard"
    }
  }
}

return M
