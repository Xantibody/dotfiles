return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
	---@module 'render-markdown'
	---@type render.md.UserConfig
	ft = "markdown",
	opts = {},
	config = function()
		require("render-markdown").setup({
			completions = { blink = { enabled = true }, lsp = { enabled = true } },
		})
	end,
}
