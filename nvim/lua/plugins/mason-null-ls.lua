return {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvimtools/none-ls.nvim",
    },
    config = function()
    -- require("your.null-ls.config") -- require your null-ls config here (example below)
    end,
}
