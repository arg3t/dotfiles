local M = { "utilyre/barbecue.nvim" }
M.name = "barbecue"
M.version = "*"
M.dependencies = {
"SmiteshP/nvim-navic",
"nvim-tree/nvim-web-devicons", -- optional dependency
}
M.config = function ()
  require("barbecue").setup {
    -- https://github.com/neovide/neovide/pull/2165
    lead_custom_section = function()
      return { { " ", "WinBar" } }
    end,
  }
end

return M


