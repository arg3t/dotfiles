
return function()
  require'persisted'.setup {
    options = {'globals'},
    pre_save = function() vim.api.nvim_exec_autocmds('User', {pattern = 'SessionSavePre'}) end,
    should_autosave = function()
      -- do not autosave if the alpha dashboard is the current filetype
      if vim.bo.filetype == "alpha" then
        return false
      end
      return true
    end,
    on_autoload_no_session = function()
      vim.notify("No existing session to load.")
    end,
    ignored_dirs = {
      "~/.config",
      "~/.local/nvim"
    },
  }
  local group = vim.api.nvim_create_augroup("PersistedHooks", {})

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "PersistedTelescopeLoadPre",
    group = group,
    callback = function(session)
      -- Save the currently loaded session using a global variable
      require("persisted").save({ session = vim.g.persisted_loaded_session })

      -- Delete all of the open buffers
      vim.api.nvim_input("<ESC>:%bd!<CR>")
    end,
  })
end
