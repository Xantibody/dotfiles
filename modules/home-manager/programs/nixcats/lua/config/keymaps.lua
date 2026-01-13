-- Global keymaps configuration
-- Migrated from nixvim configuration
local map = vim.keymap.set

-- Hlslens clear highlight
map("n", "<Leader>l", "<Cmd>noh<CR>", { noremap = true, silent = true })

-- Skkeleton keymaps
if nixCats("japanese") then
	map("i", "<C-j>", "<Plug>(skkeleton-enable)")
	map("c", "<C-j>", "<Plug>(skkeleton-enable)")
end

-- Core keymaps
if nixCats("core") then
	-- Telescope
	map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Telescope find files" })
	map("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { desc = "Telescope live grep" })
	map("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<CR>", { desc = "Telescope buffers" })
	map("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<CR>", { desc = "Telescope help tags" })

	-- Oil
	map("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open oil" })

	-- Barbar (buffer tabs)
	map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", { desc = "Previous buffer" })
	map("n", "<A-.>", "<Cmd>BufferNext<CR>", { desc = "Next buffer" })
	map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", { desc = "Move buffer previous" })
	map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", { desc = "Move buffer next" })
	map("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", { desc = "Go to buffer 1" })
	map("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", { desc = "Go to buffer 2" })
	map("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", { desc = "Go to buffer 3" })
	map("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", { desc = "Go to buffer 4" })
	map("n", "<A-5>", "<Cmd>BufferGoto 5<CR>", { desc = "Go to buffer 5" })
	map("n", "<A-6>", "<Cmd>BufferGoto 6<CR>", { desc = "Go to buffer 6" })
	map("n", "<A-7>", "<Cmd>BufferGoto 7<CR>", { desc = "Go to buffer 7" })
	map("n", "<A-8>", "<Cmd>BufferGoto 8<CR>", { desc = "Go to buffer 8" })
	map("n", "<A-9>", "<Cmd>BufferGoto 9<CR>", { desc = "Go to buffer 9" })
	map("n", "<A-0>", "<Cmd>BufferLast<CR>", { desc = "Go to last buffer" })
	map("n", "<A-p>", "<Cmd>BufferPin<CR>", { desc = "Pin/unpin buffer" })
	map("n", "<A-c>", "<Cmd>BufferClose<CR>", { desc = "Close buffer" })
	map("n", "<C-p>", "<Cmd>BufferPick<CR>", { desc = "Pick buffer" })
	map("n", "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", { desc = "Order by buffer number" })
	map("n", "<Space>bn", "<Cmd>BufferOrderByName<CR>", { desc = "Order by name" })
	map("n", "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>", { desc = "Order by directory" })
	map("n", "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>", { desc = "Order by language" })
	map("n", "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", { desc = "Order by window number" })

	-- Neogit
	map("n", "<leader>ng", "<cmd>Neogit<CR>", { desc = "Neogit" })
end

-- Display keymaps
if nixCats("display") then
	-- Flash
	local flash_opts = { noremap = true, silent = true }
	map({ "n", "x", "o" }, "s", "<cmd>lua require('flash').jump()<CR>", flash_opts)
	map({ "n", "x", "o" }, "S", "<cmd>lua require('flash').treesitter()<CR>", flash_opts)
	map("o", "r", "<cmd>lua require('flash').remote()<CR>", flash_opts)
	map({ "o", "x" }, "R", "<cmd>lua require('flash').treesitter_search()<CR>", flash_opts)
	map("c", "<C-s>", "<cmd>lua require('flash').toggle()<CR>", flash_opts)
end

-- Edit keymaps
if nixCats("edit") then
	-- in-and-out
	map("i", "<C-CR>", "<cmd>lua require('in-and-out').in_and_out()<CR>")

	-- tiny-code-action
	map({ "n", "v" }, "<leader>ca", "<cmd>lua require('tiny-code-action').code_action()<CR>", {
		noremap = true,
		silent = true,
		desc = "See available code actions",
	})

	-- Format toggle
	map({ "n", "i" }, "<C-F>", "<CMD>FormatToggle<CR>", {
		noremap = true,
		silent = true,
		desc = "toggle save format",
	})

	-- LSP keymaps
	map("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show line diagnostics" })
	map("n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", { desc = "Go to type definition" })
	map("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "Go to previous diagnostic" })
	map("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "Go to next diagnostic" })
	map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "Show documentation for what is under cursor" })
	map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { desc = "Go to declaration" })
	map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })
	map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "Go to implementation" })
	map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "Find references" })
	map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Show signature help" })
	map("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", { desc = "Add workspace folder" })
	map("n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", { desc = "Remove workspace folder" })
	map(
		"n",
		"<leader>wl",
		"<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
		{ desc = "List workspace folders" }
	)
	map("n", "<leader>rs", ":LspRestart<CR>", { desc = "Restart LSP" })
	map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
end
