-- Skkeleton (Japanese input) configuration

-- eggLikeNewline asks the completion backend whether a candidate is selected,
-- and skkeleton only knows the builtin popup menu by itself. blink-cmp-skkeleton
-- does not register a backend, so the bridge lives here. blink.cmp is loaded on
-- InsertEnter; until then no menu can be open, so it is not required here.
vim.fn["skkeleton#register_completion_backend"]("blink.cmp", {
	complete_info = function()
		local blink = package.loaded["blink.cmp"]
		if not blink or not blink.is_menu_visible() then
			return { pum_visible = false, selected = -1 }
		end
		return { pum_visible = true, selected = blink.get_selected_item() ~= nil and 1 or -1 }
	end,
	confirm_key = "<Cmd>lua require('blink.cmp').select_and_accept()",
})

vim.fn["skkeleton#config"]({
	completionBackend = "blink.cmp",
	eggLikeNewline = true,
	registerConvertResult = true,
	sources = { "skk_server" },
	-- yaskkserv2 の辞書は UTF-8 で作っている (modules/japanese/skk.nix)
	skkServerResEnc = "utf-8",
	showCandidatesCount = 999,
})

-- Skkeleton keymaps
local map = vim.keymap.set
map("i", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "SKK" })
map("c", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "SKK" })

-- lualine refresh autocmd for skkeleton mode change
vim.api.nvim_create_autocmd({ "User" }, {
	desc = "Refresh statusline to show the mode for Skkeleton",
	pattern = "skkeleton-mode-changed",
	group = vim.api.nvim_create_augroup("lualine-skkeleton-mode", {}),
	callback = function()
		require("lualine").refresh({ place = { "statusline" } })
	end,
})
