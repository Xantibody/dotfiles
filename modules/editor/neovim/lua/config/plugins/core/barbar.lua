-- Barbar (buffer tabs) configuration
require("barbar").setup({})

-- Cycling uses the builtin [b / ]b and switching uses <leader>b (telescope);
-- only closing needs barbar, since :bdelete would also close the window.
vim.keymap.set("n", "<leader>x", "<Cmd>BufferClose<CR>", { desc = "Close buffer" })
