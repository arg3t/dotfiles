local M = { "rmagatti/auto-session" }
M.config = function()
  require("auto-session").setup {
    log_level = "error",
    auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    auto_save_enabled = true,
    auto_session_enabled = true,
    bypass_session_save_file_types = {
      "alpha",
      "NvimTree",
      "aerial",
    },
    post_restore_cmds = {
      function()
        local unwanted_fts = {
          alpha = true,
          aerial = true,
          NvimTree = true,
        }
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
          -- Check if the buffer's filetype matches
          local ft = vim.api.nvim_buf_get_option(buffer, 'filetype')

          if unwanted_fts[ft] or #ft == 0 then
            -- Close the buffer
            vim.api.nvim_buf_delete(buffer, { force = true })
          end
        end
      end,

      function()
        require("nvim-tree.api").tree.open({ focus = false })
      end,
    },
    session_lens = {
      load_on_setup = true,
      theme_conf = { border = true },
      previewer = false,
    },
  }
end

return M
