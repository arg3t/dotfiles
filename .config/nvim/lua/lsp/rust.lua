M = {}

M.lsp = {
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        checkOnSave = {
          enable = true,
        },
        diagnostics = {
          enable = true,
        },
      }
    }
  }
}

-- servers provided by Nix (nix/modules/dev.nix)

return M
