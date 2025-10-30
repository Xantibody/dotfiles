return {
	"stevearc/conform.nvim",
	lazy = false,
	config = function()
		local utils = require("utils.edit")
		require("conform").setup({
			-- formatのtoggle設定
			format_on_save = function(bufnr)
				if utils.is_autoformat_enabled() then
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters = {
				typstyle = {
					command = "typstyle",
				},
			},
			formatters_by_ft = {
				go = { "gofmt" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				rust = { "rustfmt", lsp_format = "fallback" },
				typst = { "typstyle" },
				yaml = { "yamlfmt" },
				just = { "just" },
				json = { "gojq" },
			},
		})
		utils.setup_conform_nvim_commands()
		vim.api.nvim_set_keymap(
			"n",
			"<C-F>",
			"<CMD>FormatToggle<CR>",
			{ noremap = true, silent = true, desc = "toggle save format" }
		)
		vim.api.nvim_set_keymap(
			"i",
			"<C-F>",
			"<CMD>FormatToggle<CR>",
			{ noremap = true, silent = true, desc = "toggle save format" }
		)
	end,
}
