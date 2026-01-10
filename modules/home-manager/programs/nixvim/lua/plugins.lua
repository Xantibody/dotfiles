-- nvim-web-devicons (アイコン表示用)
require("nvim-web-devicons").setup({})

-- hlchunk
require("hlchunk").setup({
	chunk = {
		enable = true,
	},
})

-- in-and-out
require("in-and-out").setup({
	additional_targets = { '"', '"' },
})

-- diffview keymaps は git/diffview/config.lua に移動済み
