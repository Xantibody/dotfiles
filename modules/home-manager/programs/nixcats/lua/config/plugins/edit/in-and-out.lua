-- In-and-out configuration
require("in-and-out").setup({
	additional_targets = { '"', '"' },
})

vim.keymap.set("i", "<C-CR>", "<cmd>lua require('in-and-out').in_and_out()<CR>")
