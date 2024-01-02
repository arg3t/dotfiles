local map = vim.api.nvim_set_keymap

local harpoon = require('harpoon')

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window" })

map('n', '<Leader>tt', "<Cmd> NvimTreeToggle<CR>", {
  noremap = true,
  desc = "Toggle directory tree"
})

map('n', '<Leader>tf', "<Cmd> NvimTreeFindFile<CR>", {
  noremap = true,
  desc = "Go to current file in dir tree"
})

map('n', '<Leader>ta', "<Cmd> AerialToggle<CR>", {
  noremap = true,
  desc = "Open aerial sidebar"
})

map('n', '<Leader>tn', "<Cmd> AerialNavToggle<CR>", {
  noremap = true,
  desc = "Toggle aerial navigator"
})

map('n', '<Leader>Z', "<Cmd> lua require('zen-mode').toggle({})<CR>", {
  noremap = true,
  desc = "Toggle zen mode"
})

map('n', '<Leader>G', "<Cmd> Neogit<CR>", {
  noremap = true,
  desc = "Open Neogit"
})

map('n', '<Leader>lz', "<Cmd>DevdocsOpenFloat<CR>", {
  noremap = true,
  desc = "Open devdocs viewer"
})

vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window" })


map('n', '<Leader>C', "<Cmd>NoiceDismiss<CR>", {
  noremap = true,
  desc = "Dismiss noice notifications"
})


map('n', '<Leader>\'', "<Cmd>Telescope fd cwd=~/.config/nvim<CR>", {
  noremap = true,
  desc = "Edit config file"
})
