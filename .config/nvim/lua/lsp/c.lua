M = {}

M.lsp = {
  clangd = {
    cmd = {
      "clangd",
      "--offset-encoding=utf-16",
    }
  },
  cmake = { filetypes = { 'cmake', 'CMakeLists.txt' } },
  asm_lsp = {}
}

-- servers provided by Nix (nix/modules/dev.nix)

return M
