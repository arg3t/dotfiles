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

M.mason = { "jsonls" }

return M
