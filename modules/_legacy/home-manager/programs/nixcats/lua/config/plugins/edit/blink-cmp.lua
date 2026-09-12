-- Blink-cmp (completion) configuration
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
			lsp = {
				score_offset = 10,
			},
			snippets = {
				score_offset = 5,
			},
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
