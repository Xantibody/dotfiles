return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	keys = {
		-- tiny-code-actionに割り当てる
		-- { "<leader>ca", vim.lsp.buf.code_action, mode = { "n", "v" }, desc = "See available code actions" },
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

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemas = {
						-- other settings. note this overrides the lspconfig defaults.
						["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = {
							"**/*k8s*/**/*.yaml",
							"**/manifest/*.yaml",
						},
					},
					-- other schemas
				},
			},
		})

		--efm settings
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

		vim.lsp.enable("denols")
		vim.lsp.enable("just")
		vim.lsp.enable("jsonls")
		vim.lsp.enable("efm")
		vim.lsp.enable("yamlls")
		vim.lsp.enable("pyright")
		vim.lsp.enable("rust_analyzer")
		vim.lsp.enable("gopls")
		vim.lsp.enable("lua_ls")
		-- vim.lsp.enable("ts_ls")
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
		vim.lsp.config("tofu_ls", {
			cmd = { "opentofu-ls", "serve" },
			filetypes = { "opentofu", "opentofu-vars", "terraform" },
		})
	end,
}
