-- 自前のトグル用モジュール
local M = {}

-- 判定関数：conform.format_on_save から呼ぶ
-- デフォルトで有効、明示的にfalseが設定されている場合のみ無効
function M.is_autoformat_enabled()
	if vim.g.enable_autoformat == false then
		return false
	end
	return true
end

function M.setup_conform_nvim_commands()
	vim.api.nvim_create_user_command("FormatToggle", function()
		if vim.g.enable_autoformat == false then
			vim.g.enable_autoformat = true
		else
			vim.g.enable_autoformat = false
		end
		print("Autoformat: " .. (vim.g.enable_autoformat == false and "OFF" or "ON"))
	end, { desc = "Toggle autoformat-on-save" })

	vim.api.nvim_create_user_command("FormatEnable", function()
		vim.g.enable_autoformat = true
		print("Autoformat: ON")
	end, { desc = "Enable autoformat-on-save" })

	vim.api.nvim_create_user_command("FormatDisable", function()
		vim.g.enable_autoformat = false
		print("Autoformat: OFF")
	end, { desc = "Disable autoformat-on-save" })
end

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
	return ""
end

function M.get_autoformat_state()
	if vim.g.enable_autoformat == false then
		return "fmt:✗"
	end
	return "fmt:✓"
end

return M
