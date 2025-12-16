-- nvim-web-devicons (アイコン表示用)
require("nvim-web-devicons").setup({})

-- hlchunk
require("hlchunk").setup({
	chunk = {
		enable = true,
	},
})

-- tiny-glimmer
require("tiny-glimmer").setup({})

-- in-and-out
require("in-and-out").setup({
	additional_targets = { '"', '"' },
})

-- diffview keymaps
require("diffview").setup({
	keymaps = {
		view = {
			{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
		},
		file_panel = {
			{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close File Panel" } },
		},
		file_history_panel = {
			{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close File History" } },
		},
	},
})
