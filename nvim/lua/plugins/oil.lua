return {
  'stevearc/oil.nvim',
  lazy = false,
  opts = {
    default_file_explorer = true,
    -- show hidden files
    view_options = { show_hidden = true },
  },
  keys = {
    { "<leader>o", "<cmd>Oil<CR>", desc = "Open oil" },
  },
  dependencies = { "echasnovski/mini.icons", opts = {} },
  -- Optional dependencies
  -- dependencies = { "nvim-tree/nvim-web-devicons" },
}
