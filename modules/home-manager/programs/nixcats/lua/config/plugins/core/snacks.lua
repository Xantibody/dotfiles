-- Snacks configuration
-- Buffer switching lives in a floating overlay instead of a tabline.
require("snacks").setup({
	picker = { enabled = true },
})

-- Vertical buffer list that hovers over the editor.
-- position must be "float": any other value makes snacks build the layout as a
-- split (see snacks/layout.lua), which shrinks the editing area.
local function hover_buffers()
	Snacks.picker.buffers({
		focus = "list",
		layout = {
			preview = false,
			layout = {
				backdrop = false,
				position = "float",
				relative = "editor",
				width = 44,
				min_width = 44,
				height = 0.9,
				row = 1,
				col = 0,
				border = "rounded",
				box = "vertical",
				{ win = "input", height = 1, border = "bottom", title = " Buffers ", title_pos = "center" },
				{ win = "list", border = "none" },
			},
		},
	})
end

local map = vim.keymap.set
map("n", "<leader>e", hover_buffers, { desc = "Hovering buffer list" })
map("n", "<A-e>", hover_buffers, { desc = "Hovering buffer list" })
map("n", "<C-p>", hover_buffers, { desc = "Hovering buffer list" })
