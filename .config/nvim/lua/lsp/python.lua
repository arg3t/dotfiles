M = {}

M.lsp = {
  pyright = {
    settings = {
      pyright = {
        -- Using Ruff's import organizer
        disableOrganizeImports = true,
      },
      python = {
        analysis = {
          -- Ignore all files for analysis to exclusively use Ruff for linting
          ignore = { '*' },
        },
      },
    },
    on_new_config = function(new_config, root_dir)
      local pipfile_exists = require("lspconfig").util.search_ancestors(root_dir, function(path)
        local pipfile = require("lspconfig").util.path.join(path, "Pipfile")
        if require("lspconfig").util.path.is_file(pipfile) then
          return true
        else
          return false
        end
      end)

      if pipfile_exists then
        new_config.cmd = { "pipenv", "run", "pyright-langserver", "--stdio" }
      end
    end,
  },
  ruff = {
    init_options = {
      settings = {
        logLevel = 'info',
      }
    }
  }
}

M.mason = { "pyright", "ruff" }

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

return M
