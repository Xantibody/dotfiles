-- Plugin configurations
-- Setup plugins that are enabled via nixCats categories

-- Core plugins
if nixCats("core") then
  -- nvim-web-devicons
  require("nvim-web-devicons").setup({})

  -- Telescope
  require("telescope").setup({})

  -- Oil file manager
  require("oil").setup({
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
  })

  -- Gitsigns
  require("gitsigns").setup({})

  -- Neogit
  require("neogit").setup({})

  -- Which-key
  require("which-key").setup({})

  -- Treesitter
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = { enable = true },
  })

  -- Barbar
  require("barbar").setup({})
end

-- Display plugins
if nixCats("display") then
  -- Lualine
  require("lualine").setup({
    options = {
      theme = "auto",
      icons_enabled = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = {
        function()
          local ok, mode = pcall(vim.fn["skkeleton#mode"])
          if _G.utils then
            return _G.utils.get_skkeleton_state(ok, mode)
          end
          return ""
        end,
        function()
          if _G.utils then
            return _G.utils.get_autoformat_state()
          end
          return ""
        end,
      },
      lualine_x = { "filename", "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    extensions = { "fzf", "oil", "quickfix" },
  })

  -- Neoscroll
  require("neoscroll").setup({})

  -- hlchunk
  require("hlchunk").setup({
    chunk = {
      enable = true,
    },
  })

  -- Flash
  require("flash").setup({})
end

-- Edit plugins
if nixCats("edit") then
  -- Comment
  require("Comment").setup({})

  -- Surround
  require("nvim-surround").setup({})

  -- Autopairs
  require("nvim-autopairs").setup({})

  -- Fidget (LSP progress)
  require("fidget").setup({})

  -- Lazydev
  require("lazydev").setup({})

  -- Conform (formatter)
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      nix = { "nixfmt" },
      rust = { "rustfmt" },
      go = { "gofmt" },
      javascript = { "oxfmt" },
      typescript = { "oxfmt" },
      json = { "oxfmt" },
      css = { "oxfmt" },
      html = { "oxfmt" },
    },
    format_on_save = function()
      if vim.g.enable_autoformat == false then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
  })

  -- Blink-cmp (completion)
  require("blink.cmp").setup({
    keymap = { preset = "super-tab" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    completion = {
      documentation = { auto_show = true },
      ghost_text = { enabled = true },
    },
  })
end

-- Preview plugins
if nixCats("preview") then
  -- Render markdown
  require("render-markdown").setup({})
end
