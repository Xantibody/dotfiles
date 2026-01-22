-- Plugin configurations loader
-- Loads plugins based on nixCats categories

-- Core plugins
if nixCats("core") then
	require("config.plugins.core.icons")
	require("config.plugins.core.telescope")
	require("config.plugins.core.oil")
	require("config.plugins.core.gitsigns")
	require("config.plugins.core.neogit")
	require("config.plugins.core.which-key")
	require("config.plugins.core.treesitter")
	require("config.plugins.core.barbar")
end

-- Display plugins
if nixCats("display") then
	require("config.plugins.display.lualine")
	require("config.plugins.display.neoscroll")
	require("config.plugins.display.hlchunk")
	require("config.plugins.display.flash")
	require("config.plugins.display.smoothcursor")
	require("config.plugins.display.render-markdown")
	require("config.plugins.display.tiny-glimmer")
end

-- Edit plugins
if nixCats("edit") then
	require("config.plugins.edit.comment")
	require("config.plugins.edit.mini-surround")
	require("config.plugins.edit.mini-pairs")
	require("config.plugins.edit.fidget")
	require("config.plugins.edit.lazydev")
	require("config.plugins.edit.in-and-out")
	require("config.plugins.edit.tiny-code-action")
	require("config.plugins.edit.luasnip")
	require("config.plugins.edit.conform")
	require("config.plugins.edit.blink-cmp")
	require("config.plugins.edit.nvim-markdown")
end
