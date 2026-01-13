-- LuaSnip configuration
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
