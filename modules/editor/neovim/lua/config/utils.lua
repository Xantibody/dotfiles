local M = {}

function M.get_skkeleton_state(ok, mode)
	if not ok then
		return ""
	end

	if mode == "hira" then
		return "ひら"
	elseif mode == "kata" then
		return "カナ"
	elseif mode == "hankata" then
		return "半カナ"
	elseif mode == "zenkaku" then
		return "全英"
	elseif mode == "abbrev" then
		return "abbr"
	else
		return "英数"
	end
end

-- Make utils available globally
_G.utils = M

return M
