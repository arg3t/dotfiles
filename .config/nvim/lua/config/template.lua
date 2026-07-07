local function load_skeleton(filetype)
  -- do nothing if no filetype
  if filetype == "" then return end

  -- glob every directory of 'runtimepath' to search for skeleton/filetype
  local skeletons = vim.api.nvim_get_runtime_file('skeleton/' .. filetype, true)
  if #skeletons == 0 then return end

  -- read last skeleton into 1st line.
  vim.api.nvim_command('0read ' .. skeletons[#skeletons])
end

-- augroup setup
vim.api.nvim_create_augroup('aug_skeleton', { clear = true })
vim.api.nvim_create_autocmd('BufNewFile', {
  group = 'aug_skeleton',
  pattern = '*',
  callback = function()
    load_skeleton(vim.bo.filetype)
  end,
})
