-- Flash configuration
require("flash").setup({})

local map = vim.keymap.set
local function opts(desc)
	return { noremap = true, silent = true, desc = desc }
end
map({ "n", "x", "o" }, "s", "<cmd>lua require('flash').jump()<CR>", opts("Jump"))
map({ "n", "x", "o" }, "S", "<cmd>lua require('flash').treesitter()<CR>", opts("Select node"))
