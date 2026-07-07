local M = { "echasnovski/mini.nvim" }
M.config = function()
  require('mini.surround').setup({})
  require('mini.splitjoin').setup({})
  require('mini.trailspace').setup({})
  require('mini.comment').setup({})
  require('mini.align').setup({})

  vim.api.nvim_create_autocmd("Filetype", {
    pattern = "dashboard",
    callback = function()
      vim.b.minitrailspace_disable = true
    end
  })
end

return M
