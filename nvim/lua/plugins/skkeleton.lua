return {
	"vim-skk/skkeleton",
	event = "VeryLazy",
	dependencies = { "vim-denops/denops.vim" },
	config = function()
		vim.fn["skkeleton#config"]({
			eggLikeNewline = true,
			registerConvertResult = true,
			globalDictionaries = { "~/.skk/SKK-JISYO.L" },
		})

		vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-enable)")
		vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-enable)")
	end,
}
