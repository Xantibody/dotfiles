-- Skkeleton (Japanese input) configuration
vim.fn["skkeleton#config"]({
	eggLikeNewline = true,
	registerConvertResult = true,
	sources = { "skk_server" },
	showCandidatesCount = 999,
})

-- lualine refresh autocmd for skkeleton mode change
vim.api.nvim_create_autocmd({ "User" }, {
	desc = "Refresh statusline to show the mode for Skkeleton",
	pattern = "skkeleton-mode-changed",
	group = vim.api.nvim_create_augroup("lualine-skkeleton-mode", {}),
	callback = function()
		require("lualine").refresh({ place = { "statusline" } })
	end,
})
