local M = { "kkoomen/vim-doge" }
M.build = ':call doge#install()'
M.config = function()
vim.g.doge_enable_mappings = 0
end

return M


