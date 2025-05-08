return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	keys = {
		{
			"<leader>F",
			function()
				vim.lsp.buf.format({ async = true })
			end,
			mode = "n",
			desc = "Format buffer using LSP",
		},
		{
			"gD",
			vim.lsp.buf.declaration,
			mode = "n",
			desc = "Go to declaration",
		},
		{
			"<leader>ca",
			vim.lsp.buf.code_action,
			mode = { "n", "v" },
			desc = "See available code actions",
		},
		{
			"<leader>rn",
			vim.lsp.buf.rename,
			mode = "n",
			desc = "Smart rename",
		},
		{
			"<leader>d",
			vim.diagnostic.open_float,
			mode = "n",
			desc = "Show line diagnostics",
		},
		{
			"[d",
			vim.diagnostic.goto_prev,
			mode = "n",
			desc = "Go to previous diagnostic",
		},
		{
			"]d",
			vim.diagnostic.goto_next,
			mode = "n",
			desc = "Go to next diagnostic",
		},
		{
			"K",
			vim.lsp.buf.hover,
			mode = "n",
			desc = "Show documentation for what is under cursor",
		},
		{
			"<leader>rs",
			":LspRestart<CR>",
			mode = "n",
			desc = "Restart LSP",
		},
		{ "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
		{ "gd", vim.lsp.buf.definition, desc = "Go to definition" },
		{ "K", vim.lsp.buf.hover, desc = "Show hover information" },
		{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
		{ "<C-k>", vim.lsp.buf.signature_help, desc = "Show signature help" },
		{ "<space>wa", vim.lsp.buf.add_workspace_folder, desc = "Add workspace folder" },
		{ "<space>wr", vim.lsp.buf.remove_workspace_folder, desc = "Remove workspace folder" },
		{
			"<space>wl",
			function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
			desc = "List workspace folders",
		},
		{ "<space>D", vim.lsp.buf.type_definition, desc = "Go to type definition" },
		{ "<space>rn", vim.lsp.buf.rename, desc = "Rename symbol" },
		{ "<space>ca", vim.lsp.buf.code_action, mode = { "n", "v" }, desc = "Code action" },
		{ "gr", vim.lsp.buf.references, desc = "Find references" },
		{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
	},

	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
			end,
		})

		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		vim.lsp.enable("rust_analyzer")
		vim.lsp.enable("gopls")
		vim.lsp.enable("lua_ls")
		vim.lsp.enable("ts_ls")
		vim.lsp.enable("nixd")

		-- -- markdown settings
		-- lspconfig["marksman"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- -- yaml settings
		-- lspconfig["yamlls"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --python settings
		-- lspconfig["pylsp"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --ts, js settings
		-- lspconfig["ts_ls"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --bash settings
		-- lspconfig["bashls"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --terraform settings
		-- lspconfig["terraformls"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --astro settings
		-- lspconfig["astro"].setup({
		--   capabilities = capabilities,
		-- })
		--
		-- --typst setting
		-- lspconfig["tinymist"].setup({
		--   capabilities = capabilities,
		-- })
		--
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
