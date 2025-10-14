return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>F",
			function()
				require("conform").format({ async = true })
			end,
			-- mode = "",
			desc = "Format buffer",
		},
	},
	config = function()
		require("conform").setup({
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
			formatters = {
				typstyle = {
					command = "typstyle",
				},
				yamlfmt = {
					-- 改行を切り詰めない設定
					args = { "-formatter", "retain_line_breaks=true" },
				},
			},
			formatters_by_ft = {
				go = { "gofmt" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				rust = { "rustfmt", lsp_format = "fallback" },
				typst = { "typstyle" },
				yaml = { "yamlfmt" },
			},
		})
	end,
}
