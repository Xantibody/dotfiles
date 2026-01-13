-- Plugin configurations
-- Setup plugins that are enabled via nixCats categories

-- nvim-web-devicons
if nixCats("core") then
	require("nvim-web-devicons").setup({})
end

-- hlchunk
if nixCats("display") then
	require("hlchunk").setup({
		chunk = {
			enable = true,
		},
	})
end

-- TODO: Add more plugin configurations as migration progresses
-- Each plugin should check for its category before setup
