M = { "amitds1997/remote-nvim.nvim" }
M.version = "*"

M.dependencies = {
  "nvim-lua/plenary.nvim",         -- For standard functions
  "MunifTanjim/nui.nvim",          -- To build the plugin UI
  "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
}

M.config = true

return M
