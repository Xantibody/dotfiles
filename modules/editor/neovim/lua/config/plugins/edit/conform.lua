-- Conform (formatter) configuration
require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
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
		markdown = { "oxfmt", "mdsf" },
		mdx = { "oxfmt" },
		nix = { "nixfmt" },
		rust = { "rustfmt" },
		toml = { "oxfmt" },
		typescript = { "oxfmt" },
		typst = { "typstyle" },
		yaml = { "oxfmt" },
	},
})
