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
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "gofmt" },
				nix = { "nixfmt" },
			},
		})
	end,
}
