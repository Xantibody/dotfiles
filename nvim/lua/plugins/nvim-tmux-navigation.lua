return {
	"alexghergh/nvim-tmux-navigation",
	cmd = {
		"NvimTmuxNavigateLeft",
		"NvimTmuxNavigateDown",
		"NvimTmuxNavigateUp",
		"NvimTmuxNavigateRight",
		"NvimTmuxNavigatePrevious",
	},
	keys = {
		{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
		{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
		{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
		{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
		{ "<c-\\>", "<cmd>NvimTmuxNavigatePrevious<cr>" },
	},
	opts = {
		disable_when_zoomed = true, -- defaults to false
	},
}
