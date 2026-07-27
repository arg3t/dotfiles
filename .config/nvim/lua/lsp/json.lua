M = {}

M.lsp = {
  jsonls = {
    settings = {
      json = {
        validate = { enable = true },
      },
    },
  },
}

-- servers provided by Nix (nix/modules/dev.nix)

return M
