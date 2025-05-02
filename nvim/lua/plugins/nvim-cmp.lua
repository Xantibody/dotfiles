return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"onsails/lspkind.nvim",
		-- snipet config
		{
			"L3MON4D3/LuaSnip",
			build = (function()
				-- Build Step is needed for regex support in snippets.
				-- This step is not supported in many windows environments.
				-- Remove the below condition to re-enable on windows.
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				-- `friendly-snippets` contains a variety of premade snippets.
				-- See the README about individual language/framework/plugin snippets:
				-- https://github.com/rafamadriz/friendly-snippets
				{
					"rafamadriz/friendly-snippets",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
						require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/plugins/snippets" })
					end,
				},
			},
		},
		"saadparwaiz1/cmp_luasnip",

		-- cmp install
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",

		"f3fora/cmp-spell",
		{
			"zbirenbaum/copilot-cmp",
			config = function()
				require("copilot_cmp").setup()
			end,
		},

		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-emoji",
		"chrisgrieser/cmp-nerdfont",
	},
	config = function()
		local lspkind = require("lspkind")
		local cmp = require("cmp")
		local luasnip = require("luasnip")

		cmp.setup({
			completion = {
				completeopt = "menu, menuone, preview, noinsert",
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			}
,
			mapping = cmp.mapping.preset.insert({
				["<Tab>"] = cmp.mapping.select_next_item(),
				["<S-Tab>"] = cmp.mapping.select_prev_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = false }),
			}),

			-- sources to autocomplatetion
			sources = {
				{ name = "nvim_lsp", priority = 1200 },
				{ name = "luasnip", priority = 1100 },
				{ name = "buffer", priority = 1000 },
				{ name = "path", priority = 1000 },
				{ name = "spell", priority = 1000 },
				{ name = "nerdfont", priority = 900 },
				{ name = "copilot", priority = 800 },
				{ name = "emoji", priority = 100 },
			},

			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol",
					maxwidth = 50,
					menu = {
						buffer = "[Buffer]",
						nvim_lsp = "[LSP]",
						luasnip = "[LuaSnip]",
						nvim_lua = "[Lua]",
						path = "[Path]",
						spell = "[Spell]",
						copilot = "[Copilot]",
						emoji = "[Emoji]",
						nerdfont = "[NF]",
					},
				}),
			},
		})

		-- copilot setup
		lspkind.init({
			symbol_map = {
				Copilot = "",
			},
		})
		vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })

		-- `/` cmdline setup.
		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		-- `:` cmdline setup.
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{
					name = "cmdline",
					option = {
						ignore_cmds = { "Man", "!" },
					},
				},
			}),
		})
	end,
}
