-- Plugin configurations
-- Setup plugins that are enabled via nixCats categories

-- Core plugins
if nixCats("core") then
  -- nvim-web-devicons
  require("nvim-web-devicons").setup({})

  -- mini.icons
  require("mini.icons").setup({})

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

  -- Treesitter (grammars are provided by Nix, just enable features)
  vim.treesitter.language.register("bash", "zsh")

  -- Barbar
  require("barbar").setup({})
end

-- Display plugins
if nixCats("display") then
  -- Lualine
  require("lualine").setup({
    options = {
      theme = "everforest",
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

  -- Smooth cursor
  require("smoothcursor").setup({
    texthl = "SmoothCursorGreen",
  })

  -- Alpha (dashboard) - loaded separately in alpha.lua
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

  -- In-and-out
  require("in-and-out").setup({
    additional_targets = { '"', '"' },
  })

  -- Tiny code action
  require("tiny-code-action").setup({})

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
      default = function()
        if require("blink-cmp-skkeleton").is_enabled() then
          return { "skkeleton" }
        else
          return { "dictionary", "lazydev", "lsp", "path", "snippets", "buffer" }
        end
      end,
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 1,
        },
        skkeleton = {
          name = "skkeleton",
          module = "blink-cmp-skkeleton",
          score_offset = 100,
          min_keyword_length = 0,
        },
        dictionary = {
          module = "blink-cmp-dictionary",
          name = "Dict",
          min_keyword_length = 3,
          opts = { dictionary_directories = { vim.fn.expand("~/.config/nvim/dictionary") } },
          score_offset = -1,
        },
      },
    },
    completion = {
      documentation = {
        auto_show = true,
        window = { border = "rounded" },
      },
      ghost_text = { enabled = true },
      menu = {
        border = "rounded",
        draw = {
          columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
          treesitter = { "lsp" },
          components = {
            kind_icon = {
              text = function(ctx)
                local icon = ctx.kind_icon
                if vim.tbl_contains({ "path" }, ctx.source_name) then
                  local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                  if dev_icon then
                    icon = dev_icon
                  end
                else
                  icon = require("lspkind").symbolic(ctx.kind, { mode = "symbol" })
                end
                return icon .. ctx.icon_gap
              end,
              highlight = function(ctx)
                local hl = ctx.kind_hl
                if vim.tbl_contains({ "Path" }, ctx.source_name) then
                  local _, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                  if dev_hl then
                    hl = dev_hl
                  end
                end
                return hl
              end,
            },
          },
        },
      },
    },
  })
end

-- Preview plugins
if nixCats("preview") then
  -- Render markdown
  require("render-markdown").setup({})

  -- nvim-markdown settings
  vim.g.vim_markdown_auto_insert_bullets = 1
  vim.g.vim_markdown_new_list_item_indent = 0
  vim.g.vim_markdown_folding_disabled = 1
  vim.g.vim_markdown_toc_autofit = 1
end
