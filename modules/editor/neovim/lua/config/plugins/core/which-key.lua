-- Which-key configuration
local wk = require("which-key")
wk.setup({})

-- Labels only: the mappings themselves come from Neovim or the plugins, whose
-- descriptions are Lua calls, :help pointers or full sentences, and lazily
-- loaded plugins have none until their first key press.
wk.add({
	-- LSP (Neovim defaults)
	{ "gr", group = "LSP" },
	{ "gri", desc = "Implementation" },
	{ "grn", desc = "Rename" },
	{ "grr", desc = "References" },
	{ "grt", desc = "Type definition" },
	{ "grx", desc = "Run codelens" },
	{ "gO", desc = "Symbols" },
	{ "<C-s>", desc = "Signature help", mode = "i" },

	-- Diagnostics
	{ "[d", desc = "Prev diagnostic" },
	{ "]d", desc = "Next diagnostic" },
	{ "[D", desc = "First diagnostic" },
	{ "]D", desc = "Last diagnostic" },
	{ "<C-w>d", desc = "Line diagnostics" },
	{ "<C-w><C-d>", desc = "Line diagnostics" },

	-- Lists (Neovim defaults)
	{ "[b", desc = "Prev buffer" },
	{ "]b", desc = "Next buffer" },
	{ "[B", desc = "First buffer" },
	{ "]B", desc = "Last buffer" },
	{ "[q", desc = "Prev quickfix" },
	{ "]q", desc = "Next quickfix" },
	{ "[Q", desc = "First quickfix" },
	{ "]Q", desc = "Last quickfix" },
	{ "[<C-q>", desc = "Prev quickfix file" },
	{ "]<C-q>", desc = "Next quickfix file" },
	{ "[l", desc = "Prev loclist" },
	{ "]l", desc = "Next loclist" },
	{ "[L", desc = "First loclist" },
	{ "]L", desc = "Last loclist" },
	{ "[<C-l>", desc = "Prev loclist file" },
	{ "]<C-l>", desc = "Next loclist file" },
	{ "[a", desc = "Prev arg" },
	{ "]a", desc = "Next arg" },
	{ "[A", desc = "First arg" },
	{ "]A", desc = "Last arg" },
	{ "[t", desc = "Prev tag" },
	{ "]t", desc = "Next tag" },
	{ "[T", desc = "First tag" },
	{ "]T", desc = "Last tag" },
	{ "[<C-t>", desc = "Prev preview tag" },
	{ "]<C-t>", desc = "Next preview tag" },
	{ "[<Space>", desc = "Blank line above" },
	{ "]<Space>", desc = "Blank line below" },

	-- Treesitter selection (Neovim defaults)
	{ "an", desc = "Outer node", mode = { "x", "o" } },
	{ "in", desc = "Inner node", mode = { "x", "o" } },
	{ "[n", desc = "Prev node", mode = "x" },
	{ "]n", desc = "Next node", mode = "x" },
	{ "[N", desc = "Prev sibling", mode = "x" },
	{ "]N", desc = "Next sibling", mode = "x" },

	-- Misc (Neovim defaults)
	{ "gx", desc = "Open link", mode = { "n", "x" } },
	{ "<C-l>", desc = "Clear highlight" },

	-- comment.nvim
	{ "gc", group = "Comment", mode = { "n", "x" } },
	{ "gcc", desc = "Comment line" },
	{ "gco", desc = "Comment below" },
	{ "gcO", desc = "Comment above" },
	{ "gcA", desc = "Comment at end" },
	{ "gb", group = "Block comment", mode = { "n", "x" } },
	{ "gbc", desc = "Block comment line" },

	-- mini.surround
	{ "gs", group = "Surround" },
	{ "gsa", desc = "Add", mode = { "n", "x" } },
	{ "gsd", desc = "Delete" },
	{ "gsr", desc = "Replace" },
	{ "gsf", desc = "Find right" },
	{ "gsF", desc = "Find left" },
	{ "gsh", desc = "Highlight" },
	{ "gsn", desc = "Set search range" },

	-- Leader groups
	{ "<leader>g", group = "Git" },
})
