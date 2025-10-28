return {
	"emmanueltouzery/key-menu.nvim",
	event = "VeryLazy",
	init = function()
		-- 複数キーの判定待ち
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	config = function()
		-- 表示設定
		require("key-menu").set("n", "<Leader>")
		require("key-menu").set("n", "g")

		-- TODO:グループ設定を考える
		require("key-menu").set("n", "<Leader>g", { desc = "Git" })
	end,
}
