local M = { "stevearc/aerial.nvim" }
M.dependencies = {
  "nvim-treesitter/nvim-treesitter",
  "nvim-tree/nvim-web-devicons",
}
M.config = function()
  require('aerial').setup({
    -- Your configuration here
    -- To auto-open the aerial window on entering a buffer:
    -- on_attach = function(bufnr)
    --   vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    --   vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    --   require('aerial').open({ focus = false })
    -- end
  })
end


return M
