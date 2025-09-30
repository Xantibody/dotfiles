return {
	"vim-skk/skkeleton",
	event = "VeryLazy",
	dependencies = {
		"vim-denops/denops.vim",
	},
	config = function()
		vim.fn["skkeleton#config"]({
			eggLikeNewline = true,
			registerConvertResult = true,
			globalDictionaries = {
				"~/Library/Containers/net.mtgto.inputmethod.macSKK/Data/Documents/Dictionaries/SKK-JISYO.L",
			},
		})

		-- lualine setting
		vim.api.nvim_create_autocmd({ "User" }, {
			desc = "Refresh statusline to show the mode for Skkeleton",
			pattern = "skkeleton-mode-changed",
			group = vim.api.nvim_create_augroup("lualine-skkeleton-mode", {}),
			callback = function()
				-- 	-- tabline に表示している場合。↓を詳しくは参照。
				-- 	-- https://github.com/nvim-lualine/lualine.nvim/blob/05d78e9fd0cdfb4545974a5aa14b1be95a86e9c9/doc/lualine.txt#L975
				require("lualine").refresh({ place = { "statusline" } })
			end,
		})

		vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-enable)")
		vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-enable)")
	end,
}
