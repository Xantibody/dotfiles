-- Global keymaps configuration
local map = vim.keymap.set

-- Clear highlight
map("n", "<leader>l", "<cmd>noh<CR>", { desc = "Clear highlight" })

-- Format toggle
map("n", "<C-f>", "<cmd>FormatToggle<CR>", { desc = "Toggle auto-format" })

-- Core keymaps
if nixCats("core") then
  -- Telescope
  map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
  map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
  map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
  map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })

  -- Oil
  map("n", "<leader>o", "<cmd>Oil<CR>", { desc = "Open Oil file manager" })

  -- Barbar (buffer tabs)
  map("n", "<A-,>", "<cmd>BufferPrevious<CR>", { desc = "Previous buffer" })
  map("n", "<A-.>", "<cmd>BufferNext<CR>", { desc = "Next buffer" })
  map("n", "<A-<>", "<cmd>BufferMovePrevious<CR>", { desc = "Move buffer left" })
  map("n", "<A->>", "<cmd>BufferMoveNext<CR>", { desc = "Move buffer right" })
  map("n", "<A-1>", "<cmd>BufferGoto 1<CR>", { desc = "Go to buffer 1" })
  map("n", "<A-2>", "<cmd>BufferGoto 2<CR>", { desc = "Go to buffer 2" })
  map("n", "<A-3>", "<cmd>BufferGoto 3<CR>", { desc = "Go to buffer 3" })
  map("n", "<A-4>", "<cmd>BufferGoto 4<CR>", { desc = "Go to buffer 4" })
  map("n", "<A-5>", "<cmd>BufferGoto 5<CR>", { desc = "Go to buffer 5" })
  map("n", "<A-6>", "<cmd>BufferGoto 6<CR>", { desc = "Go to buffer 6" })
  map("n", "<A-7>", "<cmd>BufferGoto 7<CR>", { desc = "Go to buffer 7" })
  map("n", "<A-8>", "<cmd>BufferGoto 8<CR>", { desc = "Go to buffer 8" })
  map("n", "<A-9>", "<cmd>BufferGoto 9<CR>", { desc = "Go to buffer 9" })
  map("n", "<A-0>", "<cmd>BufferLast<CR>", { desc = "Go to last buffer" })
  map("n", "<A-p>", "<cmd>BufferPin<CR>", { desc = "Pin buffer" })
  map("n", "<A-c>", "<cmd>BufferClose<CR>", { desc = "Close buffer" })

  -- Neogit
  map("n", "<leader>gg", "<cmd>Neogit<CR>", { desc = "Open Neogit" })

  -- Diffview
  map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
  map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })
end

-- Japanese input
if nixCats("japanese") then
  map("i", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "Enable skkeleton" })
  map("c", "<C-j>", "<Plug>(skkeleton-enable)", { desc = "Enable skkeleton" })
end

-- Edit keymaps
if nixCats("edit") then
  -- LSP keymaps (set up in lsp.lua or via LspAttach autocmd)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local opts = { buffer = bufnr }

      map("n", "gd", vim.lsp.buf.definition, opts)
      map("n", "gD", vim.lsp.buf.declaration, opts)
      map("n", "gi", vim.lsp.buf.implementation, opts)
      map("n", "gr", vim.lsp.buf.references, opts)
      map("n", "K", vim.lsp.buf.hover, opts)
      map("n", "<leader>rn", vim.lsp.buf.rename, opts)
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
      map("n", "[d", vim.diagnostic.goto_prev, opts)
      map("n", "]d", vim.diagnostic.goto_next, opts)
      map("n", "<leader>d", vim.diagnostic.open_float, opts)
    end,
  })
end
