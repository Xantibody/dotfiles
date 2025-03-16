-- install with yarn or npm
return {
  {
    "Xantibody/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },

  {
    "ixru/nvim-markdown"
  },

  {
    "Zeioth/markmap.nvim",
    build = "yarn global add markmap-cli",
    cmd = { "MarkmapOpen", "MarkmapSave", "MarkmapWatch", "MarkmapWatchStop" },
    opts = {
      html_output = "/tmp/markmap.html", -- (default) Setting a empty string "" here means: [Current buffer path].html
      hide_toolbar = false,              -- (default)
      grace_period = 3600000             -- (default) Stops markmap watch after 60 minutes. Set it to 0 to disable the grace_period.
    },
    keys = {
      { "<leader>M", "<cmd>MarkmapWatch<CR>", desc = "Start MarkmapWatch Server" },
    },
    config = function(
        _,
        opts
    )
      require("markmap").setup(opts)
    end
  },
  {
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

}
