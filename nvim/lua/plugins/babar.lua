return {
  'romgrk/barbar.nvim',
  event = 'BufWinEnter',
  dependencies = {
    'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
  },
  keys = {
    { "<A-,>",     "<Cmd>BufferPrevious<CR>",            desc = "Previous buffer" },
    { "<A-.>",     "<Cmd>BufferNext<CR>",                desc = "Next buffer" },
    { "<A-<>",     "<Cmd>BufferMovePrevious<CR>",        desc = "Move buffer previous" },
    { "<A->>",     "<Cmd>BufferMoveNext<CR>",            desc = "Move buffer next" },
    { "<A-1>",     "<Cmd>BufferGoto 1<CR>",              desc = "Go to buffer 1" },
    { "<A-2>",     "<Cmd>BufferGoto 2<CR>",              desc = "Go to buffer 2" },
    { "<A-3>",     "<Cmd>BufferGoto 3<CR>",              desc = "Go to buffer 3" },
    { "<A-4>",     "<Cmd>BufferGoto 4<CR>",              desc = "Go to buffer 4" },
    { "<A-5>",     "<Cmd>BufferGoto 5<CR>",              desc = "Go to buffer 5" },
    { "<A-6>",     "<Cmd>BufferGoto 6<CR>",              desc = "Go to buffer 6" },
    { "<A-7>",     "<Cmd>BufferGoto 7<CR>",              desc = "Go to buffer 7" },
    { "<A-8>",     "<Cmd>BufferGoto 8<CR>",              desc = "Go to buffer 8" },
    { "<A-9>",     "<Cmd>BufferGoto 9<CR>",              desc = "Go to buffer 9" },
    { "<A-0>",     "<Cmd>BufferLast<CR>",                desc = "Go to last buffer" },
    { "<A-p>",     "<Cmd>BufferPin<CR>",                 desc = "Pin/unpin buffer" },
    { "<A-c>",     "<Cmd>BufferClose<CR>",               desc = "Close buffer" },
    { "<C-p>",     "<Cmd>BufferPick<CR>",                desc = "Pick buffer" },
    { "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", desc = "Order by buffer number" },
    { "<Space>bn", "<Cmd>BufferOrderByName<CR>",         desc = "Order by name" },
    { "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>",    desc = "Order by directory" },
    { "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>",     desc = "Order by language" },
    { "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", desc = "Order by window number" },
  },
  init = function() vim.g.barbar_auto_setup = false end,
  opts = {
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
  },
}
