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

M.mason = { "rust_analyzer" }

return M
