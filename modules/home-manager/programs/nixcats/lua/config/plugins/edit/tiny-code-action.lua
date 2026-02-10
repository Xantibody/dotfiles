-- Tiny code action configuration
require("tiny-code-action").setup({
	backend = "difftastic",
})

-- Override default gra with tiny-code-action UI
vim.keymap.set({ "n", "v" }, "gra", "<cmd>lua require('tiny-code-action').code_action()<CR>", {
	noremap = true,
	silent = true,
	desc = "Code action",
})
