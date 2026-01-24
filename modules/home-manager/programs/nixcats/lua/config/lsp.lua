-- LSP Configuration for Neovim 0.11+
-- Using native vim.lsp.config / vim.lsp.enable API

-- Diagnostic icons
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
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

-- Global capabilities for all LSP servers (blink.cmp integration)
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
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
	"basedpyright",
	"tinymist",
	"typos_lsp",
	"helm_ls",
	"denols",
	"efm",
	"fish_lsp",
}

-- Enable all servers
vim.lsp.enable(servers)

-- tsgo (TypeScript Go) - custom config
vim.lsp.config("tsgo", {
	cmd = { "tsgo", "--lsp", "-stdio" },
	filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("tsgo")

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

-- rust_analyzer with clippy
vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			check = {
				command = "clippy",
			},
		},
	},
})

-- efm for textlint
vim.lsp.config("efm", {
	filetypes = { "markdown" },
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

-- LSP keymaps (Neovim 0.11+ defaults: K=hover, grn=rename, gra=code_action, grr=references, gri=implementation, grt=type_definition)
local map = vim.keymap.set
map("n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show line diagnostics" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "Go to declaration" })
