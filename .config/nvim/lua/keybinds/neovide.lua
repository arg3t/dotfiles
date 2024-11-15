local map = vim.keymap.set
local utils = require('utils')

map("n", "<C-=>", function()
  utils.neovideScale(0.1)
end)

map("n", "<C-->", function()
  utils.neovideScale(-0.1)
end)
