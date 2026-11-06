-- Zen mode as a reading mode: one centred window, the code around the
-- function under the cursor dimmed by twilight, and the editing aids hidden.

-- tiny-inline-diagnostic loads on LspAttach, so it may not be there yet when
-- the window opens.
local function inline_diagnostics(action)
	local diag = package.loaded["tiny-inline-diagnostic"]
	if diag then
		diag[action]()
	end
end

require("zen-mode").setup({
	window = {
		width = 120,
		options = {
			number = false,
			relativenumber = false,
			list = false,
			signcolumn = "no",
			foldcolumn = "0",
			colorcolumn = "",
			scrolloff = 999,
		},
	},
	plugins = {
		options = { laststatus = 0 },
		twilight = { enabled = true },
		gitsigns = { enabled = false },
	},
	-- AIDEV-NOTE: plugins.diagnostics is left off on purpose. It calls
	-- vim.diagnostic.enable(false), which also empties <C-w>d and ]d; only the
	-- inline text is hidden here so diagnostics stay one keypress away.
	--
	-- AIDEV-NOTE: hlchunk's scope line is left on, unlike the other aids. Its
	-- arrow points at where the block under the cursor begins, which is as
	-- useful while reading as while editing.
	on_open = function()
		inline_diagnostics("disable")
	end,
	on_close = function()
		inline_diagnostics("enable")
	end,
})

vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "Reading mode" })
