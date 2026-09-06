-- Neogit configuration
require("neogit").setup({
	external_diff = {
		enabled = true,
		tool = "difftastic",
	},
})

vim.keymap.set("n", "<leader>ng", "<cmd>Neogit<CR>", { desc = "Neogit" })
