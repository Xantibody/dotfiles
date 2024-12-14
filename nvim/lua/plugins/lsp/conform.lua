return {
  'stevearc/conform.nvim',
  keys = {
    --[[ {
      -- Customize or remove this keymap to your liking
      "<leader>F",
      function()
        require("conform").format({ async = true })
      end,
      -- mode = "",
      desc = "Format buffer",
  }, ]]
  },

  opts = {},
}
