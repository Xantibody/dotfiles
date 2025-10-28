return {
	"karb94/neoscroll.nvim",
	opts = {},
	config = function()
		require("neoscroll").setup({
			-- mappingを減らす
			mappings = {
				"<C-u>",
				"<C-d>",
			},
		})
	end,
}
