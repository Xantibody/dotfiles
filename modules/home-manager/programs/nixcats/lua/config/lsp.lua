-- LSP Configuration
local lspconfig = require("lspconfig")

-- Default capabilities with blink.cmp
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- LSP servers to configure
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
}

-- Setup each server
for _, server in ipairs(servers) do
  local ok, _ = pcall(function()
    lspconfig[server].setup({
      capabilities = capabilities,
    })
  end)
  if not ok then
    vim.notify("LSP server " .. server .. " not found", vim.log.levels.WARN)
  end
end

-- Special configuration for lua_ls
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim", "nixCats" } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- Special configuration for nixd
lspconfig.nixd.setup({
  capabilities = capabilities,
  settings = {
    nixd = {
      formatting = { command = { "nixfmt" } },
    },
  },
})
