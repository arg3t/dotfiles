local M = { "nvim-tree/nvim-tree.lua" }
M.version = "*"
M.lazy = false
M.dependencies = {
  "romgrk/barbar.nvim",
  "nvim-tree/nvim-web-devicons",
}

local function open_nvim_tree(data)
  -- buffer is a real file on the disk
  local real_file = vim.fn.filereadable(data.file) == 1

  if not real_file then
    return
  end

  -- open the tree, find the file but don't focus it
  require("nvim-tree.api").tree.open({ focus = false, find_file = true, })
end

vim.api.nvim_create_autocmd({ "BufCreate" }, { callback = open_nvim_tree })

M.config = function()
  require("nvim-tree").setup({
    sort_by = "case_sensitive",
    update_focused_file = {
      enable = true,
      update_cwd = false,
    },
    view = {
      adaptive_size = true,
    },
    diagnostics = {
      enable = true,
      show_on_dirs = true
    },
    renderer = {
      group_empty = false,
    },
  })
end


return M
