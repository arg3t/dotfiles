local map = vim.api.nvim_set_keymap

map('n', '<C-t>', "<Cmd>ToggleTerm direction=horizontal<CR>", {
  noremap = true,
  desc = "Create terminal split"
})


map('n', '<C-s>', "<Cmd>ToggleTerm direction=float<CR>", {
  noremap = true,
  desc = "Toggle terminal floating"
})

local trim_spaces = true
vim.keymap.set("v", "<Leader>s", function()
    require("toggleterm").send_lines_to_terminal("visual_selection", trim_spaces, { args = vim.v.count })
end)


vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "term://*",
    callback = function()
      vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    end,
})
