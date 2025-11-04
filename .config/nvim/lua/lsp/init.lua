-- === Initialize LSP Servers ===
-- For a list of LSP Servers and documentation:
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local capabilities = require('cmp_nvim_lsp').default_capabilities()
local utils = require("utils")
local lsmod = require("lazy.core.util").lsmod


local on_attach = function(client, bufnr)
  if client.server_capabilities.documentFormattingProvider then
    vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
    vim.keymap.set("n", "<leader>gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", opts)
  end

  vim.api.nvim_create_autocmd("CursorHold", {
    buffer = bufnr,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always', -- show source in diagnostic popup window
        prefix = ' '
      }

      if not vim.b.diagnostics_pos then
        vim.b.diagnostics_pos = { nil, nil }
      end

      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      if (cursor_pos[1] ~= vim.b.diagnostics_pos[1] or cursor_pos[2] ~= vim.b.diagnostics_pos[2]) and
          #vim.diagnostic.get() > 0
      then
        vim.diagnostic.open_float(nil, opts)
      end

      vim.b.diagnostics_pos = cursor_pos
    end
  })

  -- Make K show hover menu if it is supported
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })

  -- The blow command will highlight the current variable and its usages in the buffer.
  if client.server_capabilities.document_highlight then
    vim.cmd([[
      hi! link LspReferenceRead Visual
      hi! link LspReferenceText Visual
      hi! link LspReferenceWrite Visual
      augroup lsp_document_highlight
        autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]])
  end

  if vim.g.logging_level == 'debug' then
    local msg = string.format("Language server %s started!", client.name)
    vim.notify(msg, 'info', { title = 'Nvim-config' })
  end
end


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

function lspSetup(mod)
  if mod == "lsp" then
    return
  end

  local config = require(mod)

  for k, v in pairs(config.lsp) do
    vim.lsp.config(k,
      utils.mergeTables(v, {
        -- root_dir = function()
        --   print("Setting root_dir " .. vim.loop.cwd())
        --   return vim.loop.cwd()
        -- end,
        on_attach = on_attach,
        capabilities = capabilities
      })
    )
    vim.lsp.enable(k)
  end
end

require("neoconf").setup({})

-- Load configs from lsp directory
lsmod("lsp", lspSetup)
