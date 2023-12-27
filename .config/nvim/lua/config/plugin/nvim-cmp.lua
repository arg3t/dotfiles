return function()
  local cmp = require'cmp'
  local lspkind = require('lspkind')

  cmp.setup({
    snippet = {
      expand = function(args)
        require('snippy').expand_snippet(args.body) -- For `snippy` users.
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
          if not entry then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          else
            cmp.confirm()
          end
              else
                fallback()
              end
        end, {"i","s","c",}),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'snippy' },
      { name = 'vimtex', }
    }, {
      { name = 'buffer' },
      { name = 'path' },
    }),
    formatting = {
      format = lspkind.cmp_format({
        mode = 'symbol_text',
        preset = 'codicons',
        maxwidth = 50,
        ellipsis_char = '...',
        before = function (entry, vim_item)
          return vim_item
        end
      })
    }
  })

  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' },
    }, {
      { name = 'buffer' },
    })
  })

  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    view = {
      entries = {name = 'wildmenu', separator = '|' }
    },
    sources = {
      { name = 'buffer' },
      { name = 'path' }
    }
  })

  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
end
