return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local utils = require("utils.edit")
		require("lualine").setup({
			options = {
				theme = "everforest",
			},
			sections = {
				lualine_c = {
					function()
						local ok, mode = pcall(vim.fn["skkeleton#mode"])
						return utils.get_skkeleton_state(ok, mode)
					end,
					function()
						return utils.get_autoformat_state()
					end,
				},
				lualine_x = { "filename" },
			},
			inactive_sections = {
				lualine_x = { "filename" },
			},
			extensions = {
				"fzf",
				"oil",
				"quickfix",
			},
		})
	end,
}
