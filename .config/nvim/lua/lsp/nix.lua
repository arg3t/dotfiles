M = {}

M.lsp = {
  nil_ls = {
    cmd = { "nil" },
    filetypes = { "nix" },
    settings = {
      ["nil"] = {
        formatting = {
          command = { "nixfmt" },
        },
      },
    },
  },
}

-- servers provided by Nix (nix/modules/dev.nix)

return M
