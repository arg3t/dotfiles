local function is_null_ls_formatting_enabled(bufnr)
    local file_type = vim.api.nvim_buf_get_option(bufnr, "filetype")
    local generators = require("null-ls.generators").get_available(
        file_type,
        require("null-ls.methods").internal.FORMATTING
    )
    return #generators > 0
end

local custom_attach = function(client, bufnr)
  -- null-ls formatting support
  if client.server_capabilities.documentFormattingProvider then
      if
          client.name == "null-ls" and is_null_ls_formatting_enabled(bufnr)
          or client.name ~= "null-ls"
      then
          vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
          vim.keymap.set("n", "<leader>gq", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", opts)
      else
          vim.bo[bufnr].formatexpr = nil
      end
  end

  vim.api.nvim_create_autocmd("CursorHold", {
    buffer=bufnr,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always',  -- show source in diagnostic popup window
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
    vim.notify(msg, 'info', {title = 'Nvim-config'})
  end
end

local utils = require("utils")

local lspconfigs = {
  clangd = {},
  pyright = {},
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
