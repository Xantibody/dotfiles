-- Neogit configuration
require("neogit").setup({})

vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Git status" })
