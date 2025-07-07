local function skkeleton()
	local ok, mode = pcall(vim.fn["skkeleton#mode"])
	if not ok then
		return ""
	end

	if mode == "hira" then
		return "ひら"
	elseif mode == "kata" then
		return "カタ"
	elseif mode == "hankata" then
		return "半カナ"
	elseif mode == "zenkaku" then
		return "全英"
	elseif mode == "abbrev" then
		return "abbr"
	else
		return "英数"
	end
	return ""
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		options = {
			theme = "everforest",
		},
		sections = {
			lualine_x = { skkeleton },
		},
	},
	extensions = {
		"fzf",
		"oil",
		"quickfix",
	},
}
