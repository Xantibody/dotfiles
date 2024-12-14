return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    options = {
      theme = 'everforest',
    },
    sections = {
      lualine_x = { "overseer" },
    },
  },
}
