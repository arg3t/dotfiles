return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = require("config.plugin.catppuccin"),
	},
	{
		"goolord/alpha-nvim",
		cond = vim.g.vscode == nil,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
		},
		event = "VimEnter",
		config = require("config.plugin.alpha"),
	},
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"catppuccin/nvim",
			"nvim-tree/nvim-web-devicons",
			'AndreM222/copilot-lualine',
			"zbirenbaum/copilot.lua",

		},
		config = require("config.plugin.lualine"),
	},
	{
		"utilyre/barbecue.nvim",
		name = "barbecue",
		version = "*",
		dependencies = {
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons", -- optional dependency
		},
		config = require("config.plugin.barbecue"),
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {},
	},
	{
		"lukas-reineke/headlines.nvim",
		dependencies = "nvim-treesitter/nvim-treesitter",
		opts = {},
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = require("config.plugin.harpoon2"),
	},
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"romgrk/barbar.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = require("config.plugin.nvim-tree"),
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		config = function()
			local settings = require("config.plugin.whichkey")
			require("which-key").setup(settings.opts)
			require("which-key").register(settings.register)
		end,
	},
	{
		"folke/zen-mode.nvim",
		opts = {},
	},
	{
		"gauteh/vim-cppman",
	},
	{
		"lervag/vimtex",
	},
	{
		"christoomey/vim-tmux-navigator",
	},
	{
		"echasnovski/mini.nvim",
		version = '*',
		config = require("config.plugin.mini")
	},
	{
		"tpope/vim-surround",
	},
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = require("config.plugin.null-ls"),
	},
	{
		"williamboman/mason.nvim",
		config = true,
		dependencies = {
			"neovim/nvim-lspconfig",
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"folke/neodev.nvim"
		}
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {
			ensure_installed = require("config.lsp").mason_servers
		},
		dependencies = {
			"folke/neodev.nvim"
		}
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"neovim/nvim-lspconfig",
		},
		build = ":TSUpdate",
		config = require("config.plugin.treesitter"),
	},
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"rmagatti/session-lens",
		},
		config = function()
			local telescope = require("telescope")
			local config = require("config.plugin.telescope")

			for _, ext in ipairs(config.extensions_list) do
				telescope.load_extension(ext)
			end

			telescope.setup(config)
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = require("config.plugin.noice"),
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},
	{
		"neomutt/neomutt.vim",
	},
	{
		"dcampos/nvim-snippy",
		dependencies = {
			"honza/vim-snippets",
		},
		opts = {},
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
			"neovim/nvim-lspconfig",
		},
		opts = require("config.plugin.nvim-ufo"),
	},
  {
    "vhyrro/luarocks.nvim",
    priority = 1000,
    config = true,
    opts = {
      rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" }
    }
  },
	{
		"rest-nvim/rest.nvim",
		dependencies = { { "nvim-lua/plenary.nvim" } },
		config = function()
			require("rest-nvim").setup({})
		end,
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = require("config.plugin.copilot")
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = {
			"zbirenbaum/copilot.lua",
		},
		config = true
	},
	{
		"hrsh7th/nvim-cmp",
		config = require("config.plugin.nvim-cmp"),
		dependencies = {
			"onsails/lspkind.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"dcampos/cmp-snippy",
			"micangl/cmp-vimtex",
			"dcampos/nvim-snippy",
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = require("config.plugin.ibl"),
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = true,
	},
	{
		"folke/neodev.nvim",
		opts = require("config.plugin.neodev")
	},
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"pocco81/dap-buddy.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {}
	},
	{ "nvim-neotest/nvim-nio" },
	{
		"luckasRanarison/nvim-devdocs",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = require("config.plugin.nvim-devdocs")
	},
	{
		'rmagatti/auto-session',
		config = require("config.plugin.auto-session")
	},
	{
		'rmagatti/session-lens',
		dependencies = {
			'rmagatti/auto-session',
			'nvim-telescope/telescope.nvim'
		},
		opts = {}
	},
	{
		"RRethy/vim-illuminate",
	},
	{
		"petertriho/nvim-scrollbar",
		opts = {}
	},
	{
		"kevinhwang91/nvim-hlslens",
		config = function()
			require("scrollbar.handlers.search").setup({
				override_lens = function() end,
			})
		end,
	},
	{
		'kkoomen/vim-doge',
		build = ':call doge#install()',
		config = require('config.plugin.doge')
	},
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = require("config.plugin.aerial")
	},
  {
    "ray-x/go.nvim",
    dependencies = {  -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = {"CmdlineEnter"},
    ft = {"go", 'gomod'},
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  }
}
