local M = { "goolord/alpha-nvim" }
M.cond = vim.g.vscode == nil
M.dependencies = {
  "nvim-tree/nvim-web-devicons",
  "nvim-telescope/telescope.nvim",
}

M.event = "VimEnter"
M.config = function()
  local theme = require("alpha.themes.theta")
  local art = require("art")
  local quotes = require("quotes")
  local utils = require("utils")

  -- Header
  local function apply_gradient_hl(text)
    local gradient = utils.create_gradient("#CBA6F7", "#94E2D5", #text)

    local lines = {}
    for i, line in ipairs(text) do
      local tbl = {
        type = "text",
        val = line,
        opts = {
          hl = "HeaderGradient" .. i,
          shrink_margin = false,
          position = "center",
        },
      }
      table.insert(lines, tbl)

      -- create hl group
      vim.api.nvim_set_hl(0, "HeaderGradient" .. i, { fg = gradient[i] })
    end

    return {
      type = "group",
      val = lines,
      opts = { position = "center" },
    }
  end

  local function footer_align(quote_text, width)
    local max_width = width or 35

    local tbl = {}
    for _, text in ipairs(quote_text) do
      local padded_text = require("utils").pad_string(text, max_width, "right")
      table.insert(tbl, { type = "text", val = padded_text, opts = { hl = "Comment", position = "center" } })
    end

    return {
      type = "group",
      val = tbl,
      opts = {},
    }
  end

  local function get_info()
    local lazy_stats = require("lazy").stats()
    local total_plugins = " " .. lazy_stats.loaded .. "/" .. lazy_stats.count .. " packages"
    local datetime = os.date(" %A %B %d")
    local version = vim.version()
    local nvim_version_info = "ⓥ " .. version.major .. "." .. version.minor .. "." .. version.patch

    local info_string = datetime .. "  |  " .. total_plugins .. "  |  " .. nvim_version_info

    return {
      type = "text",
      val = info_string,
      opts = {
        hl = "Delimiter",
        position = "center",
      },
    }
  end

  -- Links / tools
  local dashboard = require("alpha.themes.dashboard")
  local links = {
    type = "group",
    val = {
      dashboard.button("e", " Edit Empty Buffer", "<cmd>ene<CR>"),
      dashboard.button("s", " Open Sesssion", function() require("persistence").select() end),
      dashboard.button("o", "󰈔 Open File", "<cmd>Telescope fd<CR>"),
      dashboard.button("d", " Open Folder",
        "<cmd>let dir=system(\"zenity --file-selection --directory 2> /dev/null\")<CR><cmd>cd `=dir`<CR>"),
      dashboard.button("c", " Edit Configuration", "<cmd>cd ~/.config/nvim<CR><cmd> Telescope fd<CR>"),
      dashboard.button("u", "󰏔 Update Plugins", "<cmd>Lazy update<CR>"),
    },
    position = "center",
  }

  -- MRU
  local function get_mru(max_shown)
    local tbl = {
      { type = "text", val = "Recent Files", opts = { hl = "SpecialComment", position = "center" } },
    }

    local mru_list = theme.mru(1, "", max_shown)
    for _, file in ipairs(mru_list.val) do
      table.insert(tbl, file)
    end

    return { type = "group", val = tbl, opts = {} }
  end

  theme.config.layout = {
    { type = "padding", val = 1 },
    apply_gradient_hl(utils.random_from_list(art.all_art)),
    { type = "padding", val = 1 },
    get_info(),
    { type = "padding", val = 2 },
    links,
    { type = "padding", val = 1 },
    get_mru(5),
    { type = "padding", val = 2 },
    footer_align(utils.random_from_list(quotes.all_quotes), 50),
  }

  require("alpha").setup(theme.config)
end

return M
