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
  extensions_list = { "ui-select", "session-lens" },
}

return options
