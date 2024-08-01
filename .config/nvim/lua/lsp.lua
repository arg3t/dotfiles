-- === Initialize LSP Servers ===
-- For a list of LSP Servers and documentation:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local lspconfig = require 'lspconfig'
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local configs = require("config.lsp").lspconfigs
local on_attach = require("config.lsp").lsp_onattach
local utils = require("utils")

capabilities.textDocument.completion.completionItem.snippetSupport = true

capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

-- LSP diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  signs = true,
  virtual_text = false,
  severity_sort = true,
})

local signs = {
  Error = "",
  Warning = "",
  Hint = "",
  Information = ""
}

for type, icon in pairs(signs) do
  local hl = "LspDiagnosticsSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- LSP diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  signs = true,
  virtual_text = true,
  severity_sort = true,
})

for k, v in pairs(configs) do
  lspconfig[k].setup(
    utils.mergeTables(v, {
      root_dir = function()
        return vim.loop.cwd()
      end,
      on_attach = on_attach,
      capabilities = capabilities
    }))
end

vim.api.nvim_exec_autocmds("FileType", {})
