return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	keys = {
		{ "<leader>ca", vim.lsp.buf.code_action, mode = { "n", "v" }, desc = "See available code actions" },
		{ "<leader>rn", vim.lsp.buf.rename, mode = "n", desc = "Smart rename" },
		{ "<leader>d", vim.diagnostic.open_float, mode = "n", desc = "Show line diagnostics" },
		{ "<leader>D", vim.lsp.buf.type_definition, desc = "Go to type definition" },
		{ "[d", vim.diagnostic.goto_prev, mode = "n", desc = "Go to previous diagnostic" },
		{ "]d", vim.diagnostic.goto_next, mode = "n", desc = "Go to next diagnostic" },
		{ "K", vim.lsp.buf.hover, mode = "n", desc = "Show documentation for what is under cursor" },
		{ "gD", vim.lsp.buf.declaration, mode = "n", desc = "Go to declaration" },
		{ "gd", vim.lsp.buf.definition, desc = "Go to definition" },
		{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
		{ "gr", vim.lsp.buf.references, desc = "Find references" },
		{ "<C-k>", vim.lsp.buf.signature_help, desc = "Show signature help" },
		{ "<leader>wa", vim.lsp.buf.add_workspace_folder, desc = "Add workspace folder" },
		{ "<leader>wr", vim.lsp.buf.remove_workspace_folder, desc = "Remove workspace folder" },
		{
			"<leader>wl",
			function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
			desc = "List workspace folders",
		},
		{ "<leader>rs", ":LspRestart<CR>", mode = "n", desc = "Restart LSP" },
		{ "<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol" },
	},

	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
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
			end,
		})

		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.lsp.enable("yamlls")
		vim.lsp.enable("pyright")
		vim.lsp.enable("rust_analyzer")
		vim.lsp.enable("gopls")
		vim.lsp.enable("lua_ls")
		vim.lsp.enable("ts_ls")
		vim.lsp.enable("nixd")
		vim.lsp.enable("basedpyright")
		vim.lsp.enable("html")
		vim.lsp.enable("bashls")
		vim.lsp.enable("tinymist")
		vim.lsp.enable("hls")
		vim.lsp.enable("tofu_ls")
		vim.lsp.config("tofu_ls", {
			cmd = { "opentofu-ls", "serve" },
			filetypes = { "opentofu", "opentofu-vars", "terraform" },
		})

		--efm settings
		vim.lsp.config("efm", {
			filetypes = {
				"lua",
				"markdown",
				"markdown.mdx",
			},
			settings = {
				rootMarkers = {
					".git/",
					".textlintrc",
				},
				languages = {
					lua = {
						{
							formatCommand = "lua-format -i",
						},
					},
					markdown = {
						lintCommand = "pnpm --no-install textlint -f unix --stdin --stdin-filename ${INPUT}",
						lintFormats = { "%f:%l:%c: %m [%trror/%r]" },
						rootMarkers = { ".textlintrc" },
					},
				},
			},
		})
	end,
}
