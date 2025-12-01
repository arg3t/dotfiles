local M = { "folke/noice.nvim" }
M.event = "VeryLazy"
M.opts = {
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = false,
  },

  views = {
    -- cmdline_popup = {
    --   border = {
    --     style = "single",
    --     padding = { 0, 0 },
    --   },
    --   filter_options = {},
    --   win_options = {
    --     winblend = 10,
    --     winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    --   },
    -- },
    --
    -- popup = {
    --   border = {
    --     style = "single",
    --     padding = { 0, 0 },
    --   },
    --   win_options = {
    --     winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    --   },
    -- },
    --
    -- lsp_doc = {
    --   border = {
    --     style = "single",
    --     padding = { 0, 0 },
    --   },
    --   win_options = {
    --     winblend = 10,
    --     winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    --   },
    -- },
  },
}
M.dependencies = {
  "MunifTanjim/nui.nvim",
}

return M
