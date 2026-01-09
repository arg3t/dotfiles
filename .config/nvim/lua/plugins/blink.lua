local M = { 'saghen/blink.cmp' }

M.dependencies = {
	'rafamadriz/friendly-snippets'
}

M.version = '1.*'

---@module 'blink.cmp'
---@type blink.cmp.Config
M.opts = {
	keymap = {
		preset = 'none',
		['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
		['<C-e>'] = { 'hide' },
		['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
		['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
		['<CR>'] = { 'accept', 'fallback' },
		['<Tab>'] = {
			function(cmp)
				if cmp.is_visible() then return cmp.select_next() end
			end,
			'snippet_forward',
			'fallback',
		},
		['<S-Tab>'] = {
			function(cmp)
				if cmp.is_visible() then return cmp.select_prev() end
			end,
			'snippet_backward',
			'fallback',
		},
	},

	completion = {
		ghost_text = {
			enabled = true,
			show_with_menu = true, -- Shows ghost text for the selected item
		},
		list = {
			selection = {
				preselect = false, -- Don't automatically pick the first item
				auto_insert = true, -- Show ghost text for the current selection
			}
		},
		menu = {
			border = "single",
			direction = 'above', -- FIX: Moves menu up so it doesn't cover your typing line
			draw = {
				columns = {
					{ "label",     "label_description", gap = 1 },
					{ "kind_icon", "kind",              "source_name", gap = 1 }
				},
				components = {
					source_name = {
						width = { max = 30 },
						text = function(ctx) return "[" .. ctx.source_name .. "]" end,
						highlight = 'BlinkCmpSource',
					},
				},
			},
		},
		documentation = {
			auto_show = true,
			window = { border = "single" },
		},
	},

	sources = {
		default = { 'lsp', 'path', 'snippets', 'buffer' },
	},

	appearance = { nerd_font_variant = 'mono' },
	fuzzy = { implementation = "prefer_rust_with_warning" }
}

M.opts_extend = { "sources.default" }

return M
