-- LSP Configuration for Neovim 0.11+
-- Using vim.lsp.config instead of deprecated lspconfig

-- Diagnostic icons
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

-- LSP servers to enable
local servers = {
  "nixd",
  "lua_ls",
  "gopls",
  "rust_analyzer",
  "yamlls",
  "jsonls",
  "html",
  "bashls",
  "pyright",
  "tinymist",
  "typos_lsp",
  "ts_ls",
  "helm_ls",
  "denols",
  "efm",
}

-- Enable all servers
vim.lsp.enable(servers)

-- Custom configurations

-- lua_ls
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim", "nixCats" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- nixd
vim.lsp.config("nixd", {
  settings = {
    nixd = {
      formatting = { command = { "nixfmt" } },
    },
  },
})

-- yamlls with kubernetes schemas
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

-- efm for textlint
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
          lintCommand = "textlint --format unix --stdin --stdin-filename ${INPUT}",
          lintFormats = { "%f:%l:%c: %m" },
          formatCommand = "textlint --fix --no-color --stdin --stdin-filename ${INPUT}",
          formatStdin = true,
        },
      },
    },
  },
})
