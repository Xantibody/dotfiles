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
	"ts_ls",
	"helm_ls",
	"denols",
	"efm",
	"fish_lsp",
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

-- LSP keymaps
local map = vim.keymap.set
map("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show line diagnostics" })
map("n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "Go to type definition" })
map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "Go to previous diagnostic" })
map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "Go to next diagnostic" })
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "Show documentation for what is under cursor" })
map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "Go to declaration" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "Go to implementation" })
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "Find references" })
map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Show signature help" })
map("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", { desc = "Add workspace folder" })
map("n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", { desc = "Remove workspace folder" })
map(
	"n",
	"<leader>wl",
	"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
	{ desc = "List workspace folders" }
)
map("n", "<leader>rs", ":LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
