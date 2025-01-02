return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  keys = {
    { "<leader>F",  function() vim.lsp.buf.format({ async = true }) end, mode = "n",                      desc = "Format buffer using LSP" },
    { "gD",         vim.lsp.buf.declaration,                             mode = "n",                      desc = "Go to declaration" },
    { "<leader>ca", vim.lsp.buf.code_action,                             mode = { "n", "v" },             desc = "See available code actions" },
    { "<leader>rn", vim.lsp.buf.rename,                                  mode = "n",                      desc = "Smart rename" },
    { "<leader>d",  vim.diagnostic.open_float,                           mode = "n",                      desc = "Show line diagnostics" },
    { "[d",         vim.diagnostic.goto_prev,                            mode = "n",                      desc = "Go to previous diagnostic" },
    { "]d",         vim.diagnostic.goto_next,                            mode = "n",                      desc = "Go to next diagnostic" },
    { "K",          vim.lsp.buf.hover,                                   mode = "n",                      desc = "Show documentation for what is under cursor" },
    { "<leader>rs", ":LspRestart<CR>",                                   mode = "n",                      desc = "Restart LSP" },
    { "gD",         vim.lsp.buf.declaration,                             desc = "Go to declaration" },
    { "gd",         vim.lsp.buf.definition,                              desc = "Go to definition" },
    { "K",          vim.lsp.buf.hover,                                   desc = "Show hover information" },
    { "gi",         vim.lsp.buf.implementation,                          desc = "Go to implementation" },
    { "<C-k>",      vim.lsp.buf.signature_help,                          desc = "Show signature help" },
    { "<space>wa",  vim.lsp.buf.add_workspace_folder,                    desc = "Add workspace folder" },
    { "<space>wr",  vim.lsp.buf.remove_workspace_folder,                 desc = "Remove workspace folder" },
    {
      "<space>wl",
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      desc = "List workspace folders"
    },
    { "<space>D",  vim.lsp.buf.type_definition, desc = "Go to type definition" },
    { "<space>rn", vim.lsp.buf.rename,          desc = "Rename symbol" },
    { "<space>ca", vim.lsp.buf.code_action,     mode = { "n", "v" },           desc = "Code action" },
    { "gr",        vim.lsp.buf.references,      desc = "Find references" },
    { "gi",        vim.lsp.buf.implementation,  desc = "Go to implementation" },
  },

  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }
      end,
    })
    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- java settings
    -- Must be java17 or higher. lol
    lspconfig["jdtls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- rust settings
    lspconfig["rust_analyzer"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- lua settings
    lspconfig["lua_ls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- markdown settings
    lspconfig["marksman"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- yaml settings
    lspconfig["yamlls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --python settings
    lspconfig["pylsp"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --ts, js settings
    lspconfig["ts_ls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --bash settings
    lspconfig["bashls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --terraform settings
    lspconfig["terraformls"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --astro settings
    lspconfig["astro"].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })

    --efm settings
    lspconfig["efm"].setup({
      init_options = {
        documentFormatting = true,
      },
      filetypes = {
        'lua',
        'markdown',
        'markdown.mdx',
      },
      settings = {
        rootMarkers = {
          ".git/",
          '.textlintrc',
        },
        languages = {
          lua = {
            {
              formatCommand = "lua-format -i",
            }
          },
          markdown = {
            lintCommand = 'npx --no-install textlint -f unix --stdin --stdin-filename ${INPUT}',
            lintFormats = { '%f:%l:%c: %m [%trror/%r]' },
            rootMarkers = { '.textlintrc' }
          },
        }
      }
    })


    -- local iccheck = require("lua.plugins.lsp.custom.iccheck")

    -- --motoki settings
    vim.api.nvim_create_autocmd('BufReadPost', {
      desc = 'LSP: iccheck',
      callback = function()
        vim.lsp.start({
          capabilities = capabilities,
          cmd = { "/Users/usr0200777/.config/test/iccheck", "lsp" },
          name = 'iccheck',
          root_dir = vim.fn.getcwd(),
        })
      end
    })
  end
}
