local map = vim.api.nvim_set_keymap

map('n', '<C-.>', "<Cmd>ToggleTerm direction=horizontal<CR>", {
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
