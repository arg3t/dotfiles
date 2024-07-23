local M = { "kevinhwang91/nvim-hlslens" }
M.config = function()
require("scrollbar.handlers.search").setup({
override_lens = function() end,
})
end

return M
