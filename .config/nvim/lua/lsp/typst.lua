M = {}

M.lsp = {
  tinymist = {
    cmd = { "tinymist" },
    filetypes = { "typst" },
    settings = {
      formatterMode = "typstyle",
      formatterProseWrap = true,
      formatterPrintWidth = 80,
      formatterIndentSize = 4,
      exportPdf = "onType",
      outputPath = "$root/$name",
    },
    on_attach = function(client, bufnr)
      vim.keymap.set("n", "<leader>tp", function()
        client:exec_cmd({
          title = "pin",
          command = "tinymist.pinMain",
          arguments = { vim.api.nvim_buf_get_name(0) },
        }, { bufnr = bufnr })
      end, { desc = "[T]inymist [P]in", noremap = true })

      vim.keymap.set("n", "<leader>tu", function()
        client:exec_cmd({
          title = "unpin",
          command = "tinymist.pinMain",
          arguments = { vim.v.null },
        }, { bufnr = bufnr })
      end, { desc = "[T]inymist [U]npin", noremap = true })
    end,

  }
}

M.mason = { "tinymist" }

return M
