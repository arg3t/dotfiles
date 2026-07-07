local M = { 'saghen/blink.cmp' }

M.dependencies = {
  'rafamadriz/friendly-snippets',
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
      show_with_menu = true,
    },

    list = {
      selection = {
        preselect = false,
        auto_insert = true,
      },
    },

    menu = {
      border = 'single',

      direction_priority = { 'n', 's' },

      draw = {
        columns = {
          { 'label',     'label_description', gap = 1 },
          { 'kind_icon', 'kind',              'source_icon', gap = 1 },
        },
        components = {
          source_icon = {
            width = { max = 2 },
            text = function(ctx)
              local sid = ctx.source_id or ''
              local sname = ctx.source_name or ''

              local icons = {
                lsp = '󰿘',
                path = '󰉋',
                snippets = '󱄽',
                buffer = '󰈔',
                cmdline = '󰘳',

                ['blink.cmp.sources.lsp'] = '󰿘',
                ['blink.cmp.sources.path'] = '󰉋',
                ['blink.cmp.sources.snippets'] = '󱄽',
                ['blink.cmp.sources.buffer'] = '󰈔',
                ['blink.cmp.sources.cmdline'] = '󰘳',
                ['blink.cmp.sources.complete_func'] = '󰊪',
              }

              return icons[sid] or icons[sname] or '󰋗'
            end,
            highlight = 'BlinkCmpSource',
          },
        },
      },
    },

    documentation = {
      auto_show = true,
      window = { border = 'single' },
    },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  appearance = { nerd_font_variant = 'mono' },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
}

M.opts_extend = { 'sources.default' }

return M
