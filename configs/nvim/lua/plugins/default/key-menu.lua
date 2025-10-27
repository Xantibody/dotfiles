return {
	"linty-org/key-menu.nvim",
	event = "VeryLazy", -- 起動を軽く
	opts = {}, -- そのままでOK（必要なら設定を書く）
	init = function()
		-- 複数キーの判定待ち
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	config = function()
		-- <Space> を押したらポップアップが出る“前置きキー”として登録
		require("key-menu").set("n", "<Space>")

		-- Git サブグループの見出し
		require("key-menu").set("n", "<Space>g", { desc = "Git" })

		-- バッファ限定グループ（例）
		require("key-menu").set("n", "<Space>s", { desc = "Say something", buffer = true })
	end,
	-- ふだんのマップは lazy の keys で宣言するとスッキリ
	keys = {
		-- グローバル系
		{ "<Space>w", "<Cmd>w<CR>", desc = "Save", mode = "n" },
		{ "<Space>q", "<Cmd>q<CR>", desc = "Quit", mode = "n" },

		-- Lua 関数も可
		{
			"<Space>k",
			function()
				vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
			end,
			desc = "Erase all",
			mode = "n",
		},

		-- Git グループの中身
		{ "<Space>gs", "<Cmd>Git status<CR>", desc = "Status", mode = "n" },
		{ "<Space>gc", "<Cmd>Git commit<CR>", desc = "Commit", mode = "n" },

		-- メニューに出さない隠しマップの例（key-menu では表示されない）
		{ "<leader>1", "<Cmd>BufferLineGoToBuffer 1<CR>", desc = "HIDDEN", mode = "n" },
	},
}
