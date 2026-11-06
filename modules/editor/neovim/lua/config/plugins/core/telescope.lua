-- Telescope configuration
require("telescope").setup({})

local map = vim.keymap.set
map("n", "<leader>f", "<cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Find files" })
map("n", "<leader>/", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { desc = "Grep" })
map("n", "<leader>b", "<cmd>lua require('telescope.builtin').buffers()<CR>", { desc = "Buffers" })
