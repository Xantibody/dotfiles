return {
  "zbirenbaum/copilot.lua",
  lazy = false,
  priority = 1000,
  config = function()
    require("copilot").setup {
      suggestion = { enabled = false },
      panel = { enabled = false },
      server_opts_overrides = {
        trace = "verbose",
        cmd = {
          vim.fn.expand("~/.local/share/nvim/mason/bin/copilot-language-server"),
          "--stdio"
        },
        settings = {
          advanced = {
            listCount = 10,
            inlineSuggestCount = 3,
          },
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = true,
        gitrebase = true,
        hgcommit = false,
        svn = false,
        cvs = false,
        ["."] = false,
        ["*"] = true,
      },
    }
  end,
}
