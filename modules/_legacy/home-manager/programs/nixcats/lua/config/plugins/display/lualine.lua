-- Lualine (statusline) configuration
require("lualine").setup({
	options = {
		theme = "everforest",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = {
			function()
				local ok, mode = pcall(vim.fn["skkeleton#mode"])
				return _G.utils.get_skkeleton_state(ok, mode)
			end,
			function()
				return _G.utils.get_autoformat_state()
			end,
		},
		lualine_x = { "filename" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_x = { "filename" },
	},
	extensions = { "fzf", "oil", "quickfix" },
})
