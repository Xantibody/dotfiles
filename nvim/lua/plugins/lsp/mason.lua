return {
  "williamboman/mason.nvim",
  -- Opening a direct file has failed.
  --   event = "VeryLazy",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    local mason = require("mason")

    local mason_lspconfig = require("mason-lspconfig")

    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      }
    })

    -- Not required if installing with Mason UI
    mason_lspconfig.setup({
      ensure_installed = {
        "lua_ls",
        "jdtls",
        "rust_analyzer",
        "marksman",
        "yamlls",
        "pylsp",
        "ts_ls",
        "bashls",
        "terraformls",
        "astro"
      },

      Automatic_installed = true,
    })

    require('mason-null-ls').setup({
      ensure_installed = {
        -- 'textlint'
      },
      handlers = {},
    })
  end
}
