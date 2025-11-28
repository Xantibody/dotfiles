# LSP設定
''
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN] = signs.Warn,
            [vim.diagnostic.severity.INFO] = signs.Info,
            [vim.diagnostic.severity.HINT] = signs.Hint,
          },
        },
      })
    end,
  })

  vim.lsp.config("yamlls", {
    settings = {
      yaml = {
        schemas = {
          ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = {
            "**/*k8s*/**/*.yaml",
            "**/manifest/*.yaml",
          },
        },
      },
    },
  })

  vim.lsp.config("efm", {
    filetypes = {
      "markdown",
    },
    init_options = { documentLinting = true, documentFormatting = false },
    settings = {
      rootMarkers = {
        ".git/",
        ".textlintrc",
        ".textlintrc.json",
      },
      languages = {
        markdown = {
          {
            lintIgnoreExitCode = true,
            lintStdin = true,
            lintCommand = "textlint --format unix --stdin --stdin-filename ''${INPUT}",
            lintFormats = { "%f:%l:%c: %m" },
            formatCommand = "textlint --fix --no-color --stdin --stdin-filename ''${INPUT}",
            formatStdin = true,
          },
        },
      },
    },
  })

  vim.lsp.config("tofu_ls", {
    cmd = { "opentofu-ls", "serve" },
    filetypes = { "opentofu", "opentofu-vars", "terraform" },
  })

  vim.lsp.enable("denols")
  vim.lsp.enable("just")
  vim.lsp.enable("jsonls")
  vim.lsp.enable("efm")
  vim.lsp.enable("yamlls")
  vim.lsp.enable("pyright")
  vim.lsp.enable("rust_analyzer")
  vim.lsp.enable("gopls")
  vim.lsp.enable("lua_ls")
  vim.lsp.enable("helm_ls")
  vim.lsp.enable("fish_lsp")
  vim.lsp.enable("typos_lsp")
  vim.lsp.enable("nixd")
  vim.lsp.enable("basedpyright")
  vim.lsp.enable("html")
  vim.lsp.enable("bashls")
  vim.lsp.enable("tinymist")
  vim.lsp.enable("hls")
  vim.lsp.enable("tofu_ls")
''
