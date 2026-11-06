-- Telescope configuration
require("telescope").setup({})

local map = vim.keymap.set
map("n", "<leader>f", "<cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Telescope find files" })
map("n", "<leader>/", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { desc = "Telescope live grep" })
map("n", "<leader>b", "<cmd>lua require('telescope.builtin').buffers()<CR>", { desc = "Telescope buffers" })
