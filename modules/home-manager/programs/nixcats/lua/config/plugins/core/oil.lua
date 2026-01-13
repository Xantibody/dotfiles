-- Oil file manager configuration
require("oil").setup({
	default_file_explorer = true,
	view_options = {
		show_hidden = true,
	},
})

vim.keymap.set("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open oil" })
