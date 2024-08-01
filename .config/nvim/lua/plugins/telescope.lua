local M = { "nvim-telescope/telescope.nvim" }
M.tag = "0.1.5"
M.dependencies = {
  "nvim-lua/plenary.nvim",
  "nvim-telescope/telescope-ui-select.nvim",
}

local options = {
  defaults = {
    layout_strategy = 'horizontal',
    layout_config = {
      height = 0.95,
      prompt_position = "top"
    },
    sorting_strategy = "ascending",
    color_devicons = true,
    mappings = {
    },
  },
  pickers = {
    man_pages = {
      sections = { "2", "3" }
    }
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {
      }
    },
  },
  extensions_list = { "ui-select" },
}

M.config = function()
  local telescope = require("telescope")

  for _, ext in ipairs(options.extensions_list) do
    telescope.load_extension(ext)
  end

  telescope.setup(options)
end

return M
