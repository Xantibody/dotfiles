-- 自前のトグル用モジュール
local M = {}

-- 判定関数：conform.format_on_save から呼ぶ
function M.should_format(bufnr)
	if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
		return false
	end
	return true
end

function M.setup_commands()
	vim.api.nvim_create_user_command("FormatToggle", function(args)
		if args.bang then
			vim.b.disable_autoformat = not vim.b.disable_autoformat
			print("Autoformat (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"))
		else
			vim.g.disable_autoformat = not vim.g.disable_autoformat
			print("Autoformat (global): " .. (vim.g.disable_autoformat and "OFF" or "ON"))
		end
	end, { desc = "Toggle autoformat-on-save (use ! for buffer)", bang = true })

	vim.api.nvim_create_user_command("FormatEnable", function()
		vim.b.disable_autoformat = false
		vim.g.disable_autoformat = false
		print("Autoformat: ON")
	end, { desc = "Enable autoformat-on-save" })

	vim.api.nvim_create_user_command("FormatDisable", function(args)
		if args.bang then
			vim.b.disable_autoformat = true
			print("Autoformat (buffer): OFF")
		else
			vim.g.disable_autoformat = true
			print("Autoformat (global): OFF")
		end
	end, { desc = "Disable autoformat-on-save (use ! for buffer)", bang = true })
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


return M
