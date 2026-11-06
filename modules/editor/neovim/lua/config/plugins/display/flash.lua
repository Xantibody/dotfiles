-- Flash configuration
require("flash").setup({})

local map = vim.keymap.set
local opts = { noremap = true, silent = true }
map({ "n", "x", "o" }, "s", "<cmd>lua require('flash').jump()<CR>", opts)
map({ "n", "x", "o" }, "S", "<cmd>lua require('flash').treesitter()<CR>", opts)
