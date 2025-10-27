return {
	"vim-skk/skkeleton",
	event = "VeryLazy",
	dependencies = {
		"vim-denops/denops.vim",
	},
	config = function()
		vim.g["skkeleton#mapped_keys"] = { "<C-n>", "<C-p>" }
		vim.fn["skkeleton#config"]({
			eggLikeNewline = true,
			registerConvertResult = true,
			sources = { "skk_server" },
			-- Set showCandidatesCount to a very high number to prevent auto-conversion
			-- This forces all candidates to be shown, which blink.cmp can then display
			showCandidatesCount = 999,
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
		vim.fn["skkeleton#register_keymap"]("henkan", "<C-n>", "henkanForward")
		vim.fn["skkeleton#register_keymap"]("henkan", "<C-p>", "henkanBackward")
	end,
}
