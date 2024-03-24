return function ()
  require("barbecue").setup {
    -- https://github.com/neovide/neovide/pull/2165
    lead_custom_section = function()
      return { { " ", "WinBar" } }
    end,
  }
end
