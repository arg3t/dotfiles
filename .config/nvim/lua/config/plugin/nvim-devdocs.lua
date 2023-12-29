return function ()
  require('nvim-devdocs').setup({
      float_win = {
        relative = "editor",
        height = 50,
        width = 170,
        border = "rounded",
      },
      wrap = false,
      previewer_cmd = "glow",
      cmd_args = { "-s", "dark", "-w", "80" },
      after_open = function(bufnr)
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', ':close<CR>', {})
    end
  })
end

