-- Treesitter configuration (grammars are provided by Nix)
-- Add nvim-treesitter's runtime directory to runtimepath for inherited queries (ecma, jsx, etc.)
for _, path in ipairs(vim.api.nvim_get_runtime_file("runtime/queries", true)) do
	local runtime_dir = vim.fn.fnamemodify(path, ":h")
	vim.opt.runtimepath:append(runtime_dir)
end

-- Enable treesitter highlighting for all filetypes.
-- The filetype aliases are registered on the first FileType instead of at
-- startup so that requiring vim.treesitter stays off the startup path.
local registered = false
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		if not registered then
			registered = true
			vim.treesitter.language.register("bash", "zsh")
			vim.treesitter.language.register("tsx", "typescriptreact")
			vim.treesitter.language.register("jsx", "javascriptreact")
		end
		pcall(vim.treesitter.start)
	end,
})
