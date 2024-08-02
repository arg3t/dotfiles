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

M.mason = { "clangd", "cmake", "asm_lsp" }

return M
