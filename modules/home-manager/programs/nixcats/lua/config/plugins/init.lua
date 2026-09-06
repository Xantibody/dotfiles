-- Plugin loader
--
-- Every plugin listed here is an optional (pack/*/opt) plugin that lze
-- packadds on the first event, key, command or filetype that needs it, then
-- runs the matching config module. Library-only plugins (plenary, icons,
-- mini.nvim, treesitter, lspconfig) stay in startupPlugins and only have
-- their setup() deferred, which is what `load = noop` marks.
--
-- Events used:
--   DeferredUIEnter  right after the first frame is drawn (lze alias)
--   LspAttach        the first LSP client attaches to a buffer
--   InsertEnter / CmdlineEnter / BufWritePre
local lze = require("lze")

local function load(module)
	return function()
		require(module)
	end
end

local function noop() end

-- `nvim <dir>` must open oil immediately instead of showing an empty buffer
-- until the first key press.
local has_dir_arg = false
for _, arg in ipairs(vim.fn.argv()) do
	if vim.fn.isdirectory(arg) == 1 then
		has_dir_arg = true
	end
end

-- Treesitter only registers autocmds; it must run before the first FileType.
if nixCats("core") then
	require("config.plugins.core.treesitter")
end

lze.load({
	-- Core ---------------------------------------------------------------
	{
		"icons",
		load = noop,
		enabled = nixCats("core"),
		event = "DeferredUIEnter",
		dep_of = { "barbar.nvim", "lualine.nvim", "oil.nvim", "telescope.nvim" },
		after = load("config.plugins.core.icons"),
	},
	{
		"telescope-fzf-native.nvim",
		enabled = nixCats("core"),
		dep_of = "telescope.nvim",
	},
	{
		"telescope.nvim",
		enabled = nixCats("core"),
		cmd = "Telescope",
		keys = { "<leader>ff", "<leader>fg", "<leader>fb", "<leader>fh" },
		after = load("config.plugins.core.telescope"),
	},
	{
		"oil.nvim",
		enabled = nixCats("core"),
		lazy = not has_dir_arg,
		cmd = "Oil",
		keys = "<leader>o",
		after = load("config.plugins.core.oil"),
	},
	{
		"gitsigns.nvim",
		enabled = nixCats("core"),
		event = "DeferredUIEnter",
		after = load("config.plugins.core.gitsigns"),
	},
	{
		"diffview.nvim",
		enabled = nixCats("core"),
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
			"DiffviewFocusFiles",
			"DiffviewLog",
			"DiffviewRefresh",
			"DiffviewToggleFiles",
		},
		dep_of = "vimplugin-neogit",
		after = load("config.plugins.core.diffview"),
	},
	{
		"vimplugin-neogit",
		enabled = nixCats("core"),
		cmd = "Neogit",
		keys = "<leader>ng",
		after = load("config.plugins.core.neogit"),
	},
	{
		"which-key.nvim",
		enabled = nixCats("core"),
		event = "DeferredUIEnter",
		after = load("config.plugins.core.which-key"),
	},
	{
		"barbar.nvim",
		enabled = nixCats("core"),
		event = "DeferredUIEnter",
		after = load("config.plugins.core.barbar"),
	},

	-- Display ------------------------------------------------------------
	{
		"alpha-nvim",
		enabled = nixCats("display"),
		-- The dashboard is only shown for a bare `nvim`; otherwise :Alpha loads it.
		lazy = vim.fn.argc(-1) > 0,
		cmd = "Alpha",
		after = load("config.alpha"),
	},
	{
		"lualine.nvim",
		enabled = nixCats("display"),
		event = "DeferredUIEnter",
		after = load("config.plugins.display.lualine"),
	},
	{
		"neoscroll.nvim",
		enabled = nixCats("display"),
		keys = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
		after = load("config.plugins.display.neoscroll"),
	},
	{
		"flash.nvim",
		enabled = nixCats("display"),
		keys = {
			{ "s", mode = { "n", "x", "o" } },
			{ "S", mode = { "n", "x", "o" } },
			{ "r", mode = "o" },
			{ "R", mode = { "o", "x" } },
			{ "<C-s>", mode = "c" },
		},
		after = load("config.plugins.display.flash"),
	},
	{
		"hlchunk.nvim",
		enabled = nixCats("display"),
		event = "DeferredUIEnter",
		after = load("config.plugins.display.hlchunk"),
	},
	{
		"nvim-hlslens",
		enabled = nixCats("display"),
		keys = { "n", "N", "*", "#", "g*", "g#", "<Leader>l" },
		event = { { event = "CmdlineEnter", pattern = { "/", "?" } } },
		after = load("config.hlslens"),
	},
	{
		"quick-scope",
		enabled = nixCats("display"),
		event = "DeferredUIEnter",
	},
	{
		"vimplugin-SmoothCursor-nvim",
		enabled = nixCats("display"),
		event = "DeferredUIEnter",
		after = load("config.plugins.display.smoothcursor"),
	},
	{
		"vimplugin-tiny-glimmer-nvim",
		enabled = nixCats("display"),
		event = "DeferredUIEnter",
		after = load("config.plugins.display.tiny-glimmer"),
	},
	{
		"render-markdown.nvim",
		enabled = nixCats("display"),
		ft = "markdown",
		cmd = "RenderMarkdown",
		after = load("config.plugins.display.render-markdown"),
	},

	-- Edit ---------------------------------------------------------------
	{
		"comment.nvim",
		enabled = nixCats("edit"),
		-- gcc/gbc/gco/gcO/gcA are listed on their own because Neovim ships a
		-- builtin gcc mapping that would otherwise win over the gc stub.
		keys = { { "gc", mode = { "n", "x" } }, { "gb", mode = { "n", "x" } }, "gcc", "gbc", "gco", "gcO", "gcA" },
		after = load("config.plugins.edit.comment"),
	},
	{
		"mini.surround",
		load = noop,
		enabled = nixCats("edit"),
		keys = { { "gsa", mode = { "n", "x" } }, "gsd", "gsf", "gsF", "gsh", "gsr", "gsn" },
		after = load("config.plugins.edit.mini-surround"),
	},
	{
		"mini.pairs",
		load = noop,
		enabled = nixCats("edit"),
		event = "InsertEnter",
		after = load("config.plugins.edit.mini-pairs"),
	},
	{
		"fidget.nvim",
		enabled = nixCats("edit"),
		event = "LspAttach",
		after = load("config.plugins.edit.fidget"),
	},
	{
		"lazydev.nvim",
		enabled = nixCats("edit"),
		ft = "lua",
		-- blink's lazydev source requires the module from any filetype.
		on_require = "lazydev",
		after = load("config.plugins.edit.lazydev"),
	},
	{
		"vimplugin-in-and-out-nvim",
		enabled = nixCats("edit"),
		keys = { { "<C-CR>", mode = "i" } },
		after = load("config.plugins.edit.in-and-out"),
	},
	{
		"vimplugin-tiny-code-action-nvim",
		enabled = nixCats("edit"),
		keys = { { "gra", mode = { "n", "v" } } },
		after = load("config.plugins.edit.tiny-code-action"),
	},
	{
		"vimplugin-tiny-inline-diagnostic-nvim",
		enabled = nixCats("edit"),
		event = "LspAttach",
		after = load("config.plugins.edit.tiny-inline-diagnostic"),
	},
	{
		"luasnip",
		enabled = nixCats("edit"),
		-- blink's luasnip preset requires it inside setup().
		on_require = "luasnip",
		after = load("config.plugins.edit.luasnip"),
	},
	{
		"conform.nvim",
		enabled = nixCats("edit"),
		event = "BufWritePre",
		cmd = "ConformInfo",
		keys = { { "<C-F>", mode = { "n", "i" } } },
		after = load("config.plugins.edit.conform"),
	},
	{
		"blink.cmp",
		enabled = nixCats("edit"),
		event = { "InsertEnter", "CmdlineEnter" },
		-- config.lsp requires it for the client capabilities.
		on_require = "blink.cmp",
		after = load("config.plugins.edit.blink-cmp"),
	},
	{
		"vimplugin-nvim-markdown",
		enabled = nixCats("edit"),
		ft = "markdown",
		-- g:vim_markdown_* must be set before the plugin is sourced.
		before = load("config.plugins.edit.nvim-markdown"),
	},
	{
		"lsp",
		load = noop,
		enabled = nixCats("edit"),
		-- vim.lsp.enable() attaches to buffers that are already open.
		event = "DeferredUIEnter",
		after = load("config.lsp"),
	},

	-- Preview ------------------------------------------------------------
	{
		"markdown-preview.nvim",
		enabled = nixCats("preview"),
		ft = "markdown",
		cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
	},

	-- Japanese -----------------------------------------------------------
	{
		"denops.vim",
		enabled = nixCats("japanese"),
		event = "DeferredUIEnter",
	},
	{
		"vimplugin-skkeleton",
		enabled = nixCats("japanese"),
		-- skkeleton#config() calls into denops' autoload, so denops goes first;
		-- the server it spawns only scans the runtimepath once it is up, which
		-- is long after this synchronous packadd.
		on_plugin = "denops.vim",
		after = load("config.skkeleton"),
	},
})
