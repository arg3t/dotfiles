-- Vim/Herdr-aware pane navigation: <C-h/j/k/l> moves between Neovim splits,
-- and at a split edge hands off to herdr (or tmux) to cross the pane boundary.
-- Replaces nvim-tmux-navigation: falls back to TmuxNavigate* when $TMUX is set
-- and $HERDR_PANE_ID is not, so the tmux setup keeps working.

local M = { "paulbkim-dev/vim-herdr-navigation" }

M.lazy = false

M.config = function()
  local dir = vim.fn.finddir("vim-herdr-navigation", vim.fn.stdpath("data") .. "/lazy")
  if dir ~= "" then
    dofile(dir .. "/editor/nvim.lua")
  end
end

return M
