local utils = require("utils")

local lspconfigs = {
  clangd = {
    cmd = {
      "clangd",
      "--offset-encoding=utf-16",
    }
  },
  pyright = require("config.lsp.pyright"),
  bashls = {},
  html = {},
  tsserver = {},
  lua_ls = require("config.lsp.lua_ls"),
  cssls = {},
  asm_lsp = {},
  rust_analyzer = require("config.lsp.rust_analyzer"),
  cmake = require("config.lsp.cmake"),
  gopls = {},
  jdtls = {},
  eslint = {},
  svelte = {},
}

local lsp_extras = {
  hls = {},
}

local mason_extras = {
}

return {
  mason_servers = utils.mergeTables(utils.getTableKeys(lspconfigs), mason_extras),
  lspconfigs = utils.mergeTables(lspconfigs, lsp_extras),
  lsp_onattach = custom_attach
}
