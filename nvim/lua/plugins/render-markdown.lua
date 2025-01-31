return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = {
    "markdown",
  },
  keys = {
    { "<leader>rm", "<CMD>RenderMarkdown toggle<CR>", mode = "n", desc = "Toggle Render Markdown" }
  },
  opts = {},
  --  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
}
