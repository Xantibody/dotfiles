-- 'foldexpr' wrapper around vim.treesitter.foldexpr()
--
-- Setting 'foldmethod=expr' at startup evaluates the expression for the
-- initial empty buffer right away; going through this module keeps
-- vim.treesitter from being required until a buffer with a filetype exists.
local M = {}

function M.expr()
	if vim.bo.filetype == "" then
		return "0"
	end
	return vim.treesitter.foldexpr()
end

return M
