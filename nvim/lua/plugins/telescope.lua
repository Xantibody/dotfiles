return {
  'nvim-telescope/telescope.nvim',
  event = "VeryLazy",
  dependens = {
    "danielfalk/smart-open.nvim",
    branch = "0.2.x",
    config = function()
      require("telescope").load_extension("smart_open")
    end,
    dependencies = {
      "kkharji/sqlite.lua",
      -- Only required if using match_algorithm fzf
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
  },
  keys = {
    { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "Telescope find files" },
    { "<leader>fg", function() require('telescope.builtin').live_grep() end,  desc = "Telescope live grep" },
    { "<leader>fb", function() require('telescope.builtin').buffers() end,    desc = "Telescope buffers" },
    { "<leader>fh", function() require('telescope.builtin').help_tags() end,  desc = "Telescope help tags" },
  },
  opts = {
    -- ここにTelescopeの設定を追加できます
  },
}
