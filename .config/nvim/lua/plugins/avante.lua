M = { "yetone/avante.nvim" }
M.opts = {
  instructions_file = "CLAUDE.md",

  provider = "bedrock",
  providers = {
    bedrock = {
      model = "global.anthropic.claude-sonnet-4-5-20250929-v1:0",
      aws_profile = "bedrock",
      aws_region = "eu-central-1",
    },
  },
}

M.dependencies = {
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  --- The below dependencies are optional,
  "nvim-mini/mini.pick",           -- for file_selector provider mini.pick
  "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
  "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
  "ibhagwan/fzf-lua",              -- for file_selector provider fzf
  "stevearc/dressing.nvim",        -- for input provider dressing
  "folke/snacks.nvim",             -- for input provider snacks
  "nvim-tree/nvim-web-devicons",   -- or echasnovski/mini.icons
  "zbirenbaum/copilot.lua",        -- for providers='copilot'
  {
    -- support for image pasting
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      -- recommended settings
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        -- required for Windows users
        use_absolute_path = true,
      },
    },
  },
  {
    -- Make sure to set this up properly if you have lazy=true
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },
}

return M
