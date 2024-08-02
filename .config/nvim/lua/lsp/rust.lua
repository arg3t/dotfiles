M = {}

M.lsp = {
  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        diagnostics = {
          enable = false,
        }
      }
    }
  }
}

M.mason = { "rust_analyzer" }

return M
