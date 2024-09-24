local M = { "tomtomjhj/vscoq.nvim" }

M.dependencies = {
  "whonore/Coqtail", "neovim/nvim-lspconfig"
}

M.opts = {
  vscoq = {
    proof = {
      cursor = { sticky = true },
    },
  },
  lsp = {
    on_attach = function(client, bufnr)
      vim.keymap.set({ 'n', 'i' }, '<M-Down>', '<Cmd>VsCoq stepForward<CR>', { buffer = bufnr })
      vim.keymap.set({ 'n', 'i' }, '<M-Up>', '<Cmd>VsCoq stepBackward<CR>', { buffer = bufnr })
      vim.keymap.set({ 'n', 'i' }, '<M-Right>', '<Cmd>VsCoq interpretToPoint<CR>', { buffer = bufnr })
    end,
    autostart = true,
  },
}

return M
