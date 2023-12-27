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
    find_files = {
    },
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
  extensions_list = { "ui-select", "persisted" },
}

return options
