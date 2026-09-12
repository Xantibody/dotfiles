-- Telescope configuration
require("telescope").setup({})

local map = vim.keymap.set
map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Telescope find files" })
map("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { desc = "Telescope live grep" })
map("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<CR>", { desc = "Telescope buffers" })
map("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<CR>", { desc = "Telescope help tags" })
