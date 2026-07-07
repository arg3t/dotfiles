-- ==============================================================================
-- LSP and Diagnostics Configuration
-- ==============================================================================

-- For a list of LSP Servers and documentation:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

vim.opt.updatetime = 1500

local diagnostic_symbols = {
  ERROR = "",
  WARN  = "",
  HINT  = "",
  INFO  = "",
}

local float_opts = {
  focusable = false,
  close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
  source = "always",
  scope = "cursor",
  anchor_bias = "above",
  anchor = "NW",
}

local function diag_prefix(diagnostic)
  local s = diagnostic.severity
  if s == vim.diagnostic.severity.ERROR then return diagnostic_symbols.ERROR end
  if s == vim.diagnostic.severity.WARN then return diagnostic_symbols.WARN end
  if s == vim.diagnostic.severity.INFO then return diagnostic_symbols.INFO end
  if s == vim.diagnostic.severity.HINT then return diagnostic_symbols.HINT end
  return "■"
end

local function diag_signs()
  return {
    text = {
      [vim.diagnostic.severity.ERROR] = diagnostic_symbols.ERROR,
      [vim.diagnostic.severity.WARN]  = diagnostic_symbols.WARN,
      [vim.diagnostic.severity.HINT]  = diagnostic_symbols.HINT,
      [vim.diagnostic.severity.INFO]  = diagnostic_symbols.INFO,
    },
  }
end

vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = diag_prefix },
  signs = diag_signs(),
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = { border = "rounded", header = "", prefix = " " },
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    vim.diagnostic.config({ signs = diag_signs() })
  end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
do
  local ok, cmp_cap = pcall(require, "cmp_nvim_lsp")
  if ok and cmp_cap and cmp_cap.default_capabilities then
    capabilities = cmp_cap.default_capabilities(capabilities)
  end
end
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

local function has_hover_capability(bufnr)
  for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.server_capabilities and client.server_capabilities.hoverProvider then
      return true
    end
  end
  return false
end

local function line_diags(bufnr)
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  return vim.diagnostic.get(bufnr, { lnum = lnum })
end

local function show_diags_or_hover(bufnr, prefer)
  local diags = line_diags(bufnr)
  if #diags > 0 then
    vim.diagnostic.open_float(nil, float_opts)
    return true
  end

  if has_hover_capability(bufnr) then
    if prefer == "noice" then
      require("noice.lsp").hover()
    else
      vim.lsp.buf.hover()
    end
    return true
  end

  return false
end

local function toggle_inlay_hints()
  if not vim.lsp.inlay_hint then return end
  local enabled = vim.lsp.inlay_hint.is_enabled()
  vim.lsp.inlay_hint.enable(not enabled)
  print(not enabled and "Inlay hints enabled" or "Inlay hints disabled")
end

local on_attach = function(client, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
  end

  if client.server_capabilities.definitionProvider then
    map("n", "<leader>gd", vim.lsp.buf.definition, "Goto Definition")
    map("n", "<leader>gD", vim.lsp.buf.declaration, "Goto Declaration")
  end
  if client.server_capabilities.typeDefinitionProvider then
    map("n", "<leader>gy", vim.lsp.buf.type_definition, "Goto Type Definition")
  end
  if client.server_capabilities.implementationProvider then
    map("n", "<leader>gi", vim.lsp.buf.implementation, "Goto Implementation")
  end
  if client.server_capabilities.referencesProvider then
    map("n", "<leader>gr", vim.lsp.buf.references, "Goto References")
  end
  if client.server_capabilities.renameProvider then
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
  end
  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
    map("n", "<leader>gq", function() vim.lsp.buf.format({ async = true }) end, "Format Buffer")
  end

  if client.server_capabilities.documentHighlightProvider then
    vim.cmd([[
      hi! link LspReferenceRead Visual
      hi! link LspReferenceText Visual
      hi! link LspReferenceWrite Visual
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]])
  end

  if vim.g.logging_level == "debug" then
    vim.notify(("Language server %s started!"):format(client.name), vim.log.levels.INFO, { title = "Nvim-config" })
  end

  if vim.lsp.inlay_hint then
    vim.lsp.inlay_hint.enable(false)
  end
end

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    if vim.fn.mode() == "i" then return end
    show_diags_or_hover(0, "noice")
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", function()
      show_diags_or_hover(event.buf, "noice")
    end, { buffer = event.buf, silent = true })

    vim.keymap.set("n", "<leader>hh", toggle_inlay_hints, { buffer = event.buf, desc = "Toggle inlay hints" })
  end,
})

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Set diagnostic loclist" })
vim.keymap.set("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Set diagnostic qflist" })

local utils = require("utils")
local lsmod = require("lazy.core.util").lsmod

local function lspSetup(mod)
  if mod == "lsp" then return end
  local config = require(mod)

  for server, server_conf in pairs(config.lsp) do
    local v_attach = server_conf.on_attach
    local conf = utils.mergeTables(server_conf, {
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        if v_attach then v_attach(client, bufnr) end
      end,
      capabilities = capabilities,
    })

    vim.lsp.config(server, conf)
    vim.lsp.enable(server)
  end
end

require("neoconf").setup({})
lsmod("lsp", lspSetup)
