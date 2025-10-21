return {
	"cenk1cenk2/schema-companion.nvim",
	dependencies = {
		{ "nvim-lua/plenary.nvim" },
	},
	config = function()
		require("schema-companion").setup({
			log_level = vim.log.levels.INFO,
		})
		-- require("telescope").load_extension("schema_companion")
	end,
}
