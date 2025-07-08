return {
	"saghen/blink.cmp",
	event = { "InsertEnter", "CmdLineEnter" },
	dependencies = {
		{ "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" } },
		"saghen/blink.compat",
		"uga-rosa/cmp-skkeleton",
		"onsails/lspkind.nvim",
		"nvim-tree/nvim-web-devicons",
		{ "Kaiser-Yang/blink-cmp-dictionary", dependencies = { "nvim-lua/plenary.nvim" } },
	},
	version = "1.*",
	build = "nix run .#build-plugin",

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = "super-tab" },
		snippets = { preset = "luasnip" },
		appearance = {
			nerd_font_variant = "mono",
		},
		completion = {
			documentation = {
				auto_show = true,
				window = { border = "rounded" },
				-- auto_show_delay_ms = 500,
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
									icon = require("lspkind").symbolic(ctx.kind, {
										mode = "symbol",
									})
								end

								return icon .. ctx.icon_gap
							end,

							highlight = function(ctx)
								local hl = ctx.kind_hl
								if vim.tbl_contains({ "Path" }, ctx.source_name) then
									local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
									if dev_icon then
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

		-- TODO: 設定が長すぎるので,メソッド化かファイル分割を検討したい
		sources = {
			default = { "dictionary", "lazydev", "lsp", "path", "snippets", "buffer", "skkeleton" },
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 1,
				},
				skkeleton = {
					name = "skkeleton",
					module = "blink.compat.source",
					-- 日本語入力はほかとconflictしないはず
					score_offset = 1,
				},
				dictionary = {
					module = "blink-cmp-dictionary",
					name = "Dict",
					min_keyword_length = 3,
					opts = { dictionary_directories = { vim.fn.expand("~/.config/nvim/dictionary") } },
					-- snippets以下にしたいが方法不明
					score_offset = -1,
				},
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
