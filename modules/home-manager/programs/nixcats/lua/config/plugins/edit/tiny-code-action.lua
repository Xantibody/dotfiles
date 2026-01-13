-- Tiny code action configuration
require("tiny-code-action").setup({})

vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>lua require('tiny-code-action').code_action()<CR>", {
	noremap = true,
	silent = true,
	desc = "See available code actions",
})
