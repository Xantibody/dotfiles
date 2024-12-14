return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
        filetypes = {
          ["*"] = true,
      },
        suggestion = {enabled = false},
        panel = { enabled = false},
    },
}
