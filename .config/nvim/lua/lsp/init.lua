-- ==============================================================================
-- LSP and Diagnostics Configuration
-- ==============================================================================

-- For a list of LSP Servers and documentation:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md

-- === Basic settings ===
vim.opt.updatetime = 600 -- CursorHold delay

-- Diagnostic symbols
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

-- Global diagnostic config
vim.diagnostic.config({
  virtual_text = {
    source = "always",
    spacing = 4,
    prefix = function(diagnostic)
      local s = diagnostic.severity
      if s == vim.diagnostic.severity.ERROR then return diagnostic_symbols.ERROR end
      if s == vim.diagnostic.severity.WARN then return diagnostic_symbols.WARN end
      if s == vim.diagnostic.severity.INFO then return diagnostic_symbols.INFO end
      if s == vim.diagnostic.severity.HINT then return diagnostic_symbols.HINT end
      return "■"
    end,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = diagnostic_symbols.ERROR,
      [vim.diagnostic.severity.WARN]  = diagnostic_symbols.WARN,
      [vim.diagnostic.severity.HINT]  = diagnostic_symbols.HINT,
      [vim.diagnostic.severity.INFO]  = diagnostic_symbols.INFO,
    },
  },
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = " ",
  },
})

-- Ensure diagnostic signs persist when entering windows (some plugins change config)
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    vim.diagnostic.config({
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = diagnostic_symbols.ERROR,
          [vim.diagnostic.severity.WARN]  = diagnostic_symbols.WARN,
          [vim.diagnostic.severity.HINT]  = diagnostic_symbols.HINT,
          [vim.diagnostic.severity.INFO]  = diagnostic_symbols.INFO,
        },
      },
    })
  end,
})

-- === Common capabilities (example using cmp_nvim_lsp) ===
local capabilities_ok, cmp_cap = pcall(require, "cmp_nvim_lsp")
local capabilities = vim.lsp.protocol.make_client_capabilities()
if capabilities_ok and cmp_cap and cmp_cap.default_capabilities then
  capabilities = cmp_cap.default_capabilities(capabilities)
end

-- Add snippet & other typical capabilities
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

-- === on_attach ===
local on_attach = function(client, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = bufnr, desc = desc })
  end

  -- basic LSP keymaps (only mapping examples used earlier)
  if client.server_capabilities.definitionProvider then
    map('n', '<leader>gd', vim.lsp.buf.definition, "Goto Definition")
    map('n', '<leader>gD', vim.lsp.buf.declaration, "Goto Declaration")
  end
  if client.server_capabilities.typeDefinitionProvider then
    map('n', '<leader>gy', vim.lsp.buf.type_definition, "Goto Type Definition")
  end
  if client.server_capabilities.implementationProvider then
    map('n', '<leader>gi', vim.lsp.buf.implementation, "Goto Implementation")
  end
  if client.server_capabilities.referencesProvider then
    map('n', '<leader>gr', vim.lsp.buf.references, "Goto References")
  end
  if client.server_capabilities.renameProvider then
    map('n', '<leader>rn', vim.lsp.buf.rename, "Rename")
  end
  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
    map('n', '<leader>gq', function() vim.lsp.buf.format({ async = true }) end, "Format Buffer")
  end

  -- Document highlight if supported
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

  if vim.g.logging_level == 'debug' then
    vim.notify(("Language server %s started!"):format(client.name), vim.log.levels.INFO, { title = "Nvim-config" })
  end
end

-- === CursorHold autocmd: diagnostics first, otherwise hover ===
function hover_shown()
  local base_win_id = vim.api.nvim_get_current_win()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  for _, win_id in ipairs(windows) do
    if win_id ~= base_win_id then
      local win_cfg = vim.api.nvim_win_get_config(win_id)
      if win_cfg.relative == "win" and win_cfg.win == base_win_id then
        return true
      end
    end
  end
  return false
end

function has_hover_capability(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in pairs(clients) do
    if client.server_capabilities.hoverProvider then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    if vim.fn.mode() == "i" then return end

    local bufnr = 0
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diags = vim.diagnostic.get(bufnr, { lnum = cursor_line })

    if #diags > 0 then
      -- show diagnostics (non-focusable)
      vim.diagnostic.open_float(nil, float_opts)
      return
    end

    if not hover_shown() and has_hover_capability(bufnr) then
      require("noice.lsp").hover()
    end
  end,
})

-- === Keymaps for hover and diagnostics ===
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", function()
      if not hover_shown() and has_hover_capability(event.buf) then
        require("noice.lsp").hover()
      end
    end, { buffer = event.buf, remap = false, silent = true })
  end
})

-- diagnostic navigation keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { desc = "Set diagnostic loclist" })


-- === LSP Server Setup Function ===
local utils = require("utils")
local lsmod = require("lazy.core.util").lsmod

function lspSetup(mod)
  if mod == "lsp" then
    return
  end

  local config = require(mod)

  for k, v in pairs(config.lsp) do
    local v_attach = v.on_attach
    local conf = utils.mergeTables(v, {
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        if v_attach then
          v_attach(client, bufnr)
        end
      end,
      capabilities = capabilities
    })

    vim.lsp.config(k, conf)
    vim.lsp.enable(k)
  end
end

require("neoconf").setup({})

-- Load configs from lsp directory
lsmod("lsp", lspSetup)
