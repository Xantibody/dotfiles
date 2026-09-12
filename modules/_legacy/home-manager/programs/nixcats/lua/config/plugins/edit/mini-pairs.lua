-- Pairs configuration (using mini.pairs)
require("mini.pairs").setup({
	mappings = {
		-- Disable quote pairs (handled by surround)
		['"'] = false,
		["'"] = false,
		["`"] = false,
	},
})
