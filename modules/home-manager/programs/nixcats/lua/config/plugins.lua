-- Plugin configurations
-- Setup plugins that are enabled via nixCats categories
-- Migrated from nixvim configuration

-- Core plugins
if nixCats("core") then
	local map = vim.keymap.set

	-- nvim-web-devicons
	require("nvim-web-devicons").setup({})

	-- mini.icons
	require("mini.icons").setup({})

	-- Telescope
	require("telescope").setup({})
	map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<CR>", { desc = "Telescope find files" })
	map("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { desc = "Telescope live grep" })
	map("n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<CR>", { desc = "Telescope buffers" })
	map("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<CR>", { desc = "Telescope help tags" })

	-- Oil file manager
	require("oil").setup({
		default_file_explorer = true,
		view_options = {
			show_hidden = true,
		},
	})
	map("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open oil" })

	-- Gitsigns
	require("gitsigns").setup({})

	-- Neogit
	require("neogit").setup({})
	map("n", "<leader>ng", "<cmd>Neogit<CR>", { desc = "Neogit" })

	-- Which-key
	require("which-key").setup({})

	-- Treesitter (grammars are provided by Nix)
	vim.treesitter.language.register("bash", "zsh")

	-- Barbar
	require("barbar").setup({})
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
end

-- Display plugins
if nixCats("display") then
	local map = vim.keymap.set

	-- Lualine (same as nixvim)
	require("lualine").setup({
		options = {
			theme = "everforest",
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff", "diagnostics" },
			lualine_c = {
				function()
					local ok, mode = pcall(vim.fn["skkeleton#mode"])
					return _G.utils.get_skkeleton_state(ok, mode)
				end,
				function()
					return _G.utils.get_autoformat_state()
				end,
			},
			lualine_x = { "filename" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_x = { "filename" },
		},
		extensions = { "fzf", "oil", "quickfix" },
	})

	-- Neoscroll
	require("neoscroll").setup({})

	-- hlchunk
	require("hlchunk").setup({
		chunk = {
			enable = true,
		},
	})

	-- Flash
	require("flash").setup({})
	local flash_opts = { noremap = true, silent = true }
	map({ "n", "x", "o" }, "s", "<cmd>lua require('flash').jump()<CR>", flash_opts)
	map({ "n", "x", "o" }, "S", "<cmd>lua require('flash').treesitter()<CR>", flash_opts)
	map("o", "r", "<cmd>lua require('flash').remote()<CR>", flash_opts)
	map({ "o", "x" }, "R", "<cmd>lua require('flash').treesitter_search()<CR>", flash_opts)
	map("c", "<C-s>", "<cmd>lua require('flash').toggle()<CR>", flash_opts)

	-- Smooth cursor
	require("smoothcursor").setup({
		texthl = "SmoothCursorGreen",
	})
end

-- Edit plugins
if nixCats("edit") then
	local map = vim.keymap.set

	-- Comment
	require("Comment").setup({})

	-- Surround
	require("nvim-surround").setup({})

	-- Autopairs
	require("nvim-autopairs").setup({})

	-- Fidget (LSP progress)
	require("fidget").setup({})

	-- Lazydev
	require("lazydev").setup({})

	-- In-and-out
	require("in-and-out").setup({
		additional_targets = { '"', '"' },
	})
	map("i", "<C-CR>", "<cmd>lua require('in-and-out').in_and_out()<CR>")

	-- Tiny code action
	require("tiny-code-action").setup({})
	map({ "n", "v" }, "<leader>ca", "<cmd>lua require('tiny-code-action').code_action()<CR>", {
		noremap = true,
		silent = true,
		desc = "See available code actions",
	})

	-- LuaSnip setup
	local ls = require("luasnip")
	ls.config.set_config({ enable_autosnippets = true })
	-- Load friendly-snippets
	require("luasnip.loaders.from_vscode").lazy_load()
	-- Custom snippets
	local s = ls.snippet
	local t = ls.text_node
	local i = ls.insert_node
	local f = ls.function_node
	ls.add_snippets("markdown", {
		s("hugo", {
			t("+++"),
			t({ "", "date = '" }),
			f(function()
				return os.date("%Y-%m-%dT%H:%M:%S+09:00")
			end, {}),
			t({ "'", "title = '" }),
			i(1, "タイトル"),
			t({ "'", "categories = ['" }),
			i(2, "ぎじゅつ"),
			t({ "']", "draft = true", "tags = ['" }),
			i(3, "Rust"),
			t({ "']", "+++", "", "" }),
			i(0),
		}),
	})

	-- Conform (formatter) - same as nixvim
	require("conform").setup({
		format_on_save = function(bufnr)
			if _G.utils.is_autoformat_enabled() then
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters = {
			typstyle = { command = "typstyle" },
		},
		formatters_by_ft = {
			css = { "oxfmt" },
			go = { "gofmt" },
			html = { "oxfmt" },
			javascript = { "oxfmt" },
			javascriptreact = { "oxfmt" },
			json = { "oxfmt" },
			json5 = { "oxfmt" },
			jsonc = { "oxfmt" },
			just = { "just" },
			lua = { "stylua" },
			markdown = { "oxfmt" },
			mdx = { "oxfmt" },
			nix = { "nixfmt" },
			rust = { "rustfmt" },
			toml = { "oxfmt" },
			typescript = { "oxfmt" },
			typst = { "typstyle" },
			yaml = { "oxfmt" },
		},
	})
	map({ "n", "i" }, "<C-F>", "<CMD>FormatToggle<CR>", {
		noremap = true,
		silent = true,
		desc = "toggle save format",
	})

	-- Blink-cmp (completion) - same as nixvim
	require("blink.cmp").setup({
		keymap = { preset = "super-tab" },
		snippets = { preset = "luasnip" },
		appearance = { nerd_font_variant = "mono" },
		completion = {
			documentation = {
				auto_show = true,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = true },
			menu = {
				border = "rounded",
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
					treesitter = { "lsp" },
					components = {
						kind_icon = {
							text = function(ctx)
								local icon = ctx.kind_icon
								if vim.tbl_contains({ "path" }, ctx.source_name) then
									local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
									if dev_icon then
										icon = dev_icon
									end
								else
									icon = require("lspkind").symbolic(ctx.kind, { mode = "symbol" })
								end
								return icon .. ctx.icon_gap
							end,
							highlight = function(ctx)
								local hl = ctx.kind_hl
								if vim.tbl_contains({ "Path" }, ctx.source_name) then
									local _, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
									if dev_hl then
										hl = dev_hl
									end
								end
								return hl
							end,
						},
					},
				},
			},
		},
		sources = {
			default = function()
				if require("blink-cmp-skkeleton").is_enabled() then
					return { "skkeleton" }
				else
					return { "lsp", "path", "snippets", "buffer", "lazydev", "dictionary" }
				end
			end,
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 1,
				},
				skkeleton = {
					name = "skkeleton",
					module = "blink-cmp-skkeleton",
					score_offset = 100,
					min_keyword_length = 0,
				},
				dictionary = {
					module = "blink-cmp-dictionary",
					name = "Dict",
					min_keyword_length = 3,
					score_offset = -1,
					opts = { dictionary_directories = { vim.fn.expand("~/.config/nvim/dictionary") } },
				},
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	})
end

-- Preview plugins
if nixCats("preview") then
	-- Render markdown
	require("render-markdown").setup({})

	-- nvim-markdown settings
	vim.g.vim_markdown_auto_insert_bullets = 1
	vim.g.vim_markdown_new_list_item_indent = 0
	vim.g.vim_markdown_folding_disabled = 1
	vim.g.vim_markdown_toc_autofit = 1
end
