-- Treesitter configuration (grammars are provided by Nix)
vim.treesitter.language.register("bash", "zsh")

-- Enable treesitter highlighting for all filetypes
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
