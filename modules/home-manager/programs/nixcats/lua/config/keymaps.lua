-- Global keymaps configuration
local map = vim.keymap.set

-- Clear highlight
map("n", "<leader>l", "<cmd>noh<CR>", { desc = "Clear highlight" })

-- Skkeleton toggle
map("i", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "Enable skkeleton" })
map("c", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "Enable skkeleton" })

-- Code action (if tiny-code-action is available)
map({ "n", "v" }, "<leader>ca", function()
	require("tiny-code-action").code_action()
end, { desc = "Code action" })

-- Format toggle
map("n", "<C-f>", "<cmd>FormatToggle<CR>", { desc = "Toggle auto-format" })

-- TODO: Add more keymaps as migration progresses
-- Telescope, Oil, Barbar, LSP keymaps will be added
