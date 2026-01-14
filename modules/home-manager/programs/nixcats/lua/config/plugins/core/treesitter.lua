-- Treesitter configuration (grammars are provided by Nix)
-- Add nvim-treesitter's runtime directory to runtimepath for inherited queries (ecma, jsx, etc.)
for _, path in ipairs(vim.api.nvim_get_runtime_file("runtime/queries", true)) do
	local runtime_dir = vim.fn.fnamemodify(path, ":h")
	vim.opt.runtimepath:append(runtime_dir)
end

-- Register additional filetype mappings
vim.treesitter.language.register("bash", "zsh")
vim.treesitter.language.register("tsx", "typescriptreact")
vim.treesitter.language.register("jsx", "javascriptreact")

-- Enable treesitter highlighting for all filetypes
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
