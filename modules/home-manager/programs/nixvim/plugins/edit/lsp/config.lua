-- LSP診断アイコン設定
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

-- yamlls カスタム設定 (kubernetes schemas)
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

-- efm カスタム設定 (textlint for markdown)
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

-- tofu_ls カスタム設定
vim.lsp.config("tofu_ls", {
	cmd = { "opentofu-ls", "serve" },
	filetypes = { "opentofu", "opentofu-vars", "terraform" },
})
