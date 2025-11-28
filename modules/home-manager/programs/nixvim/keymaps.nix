# キーマップ設定
[
  # LSP keymaps
  {
    key = "<leader>d";
    action = "<cmd>lua vim.diagnostic.open_float()<CR>";
    mode = "n";
    options.desc = "Show line diagnostics";
  }
  {
    key = "<leader>D";
    action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
    mode = "n";
    options.desc = "Go to type definition";
  }
  {
    key = "[d";
    action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
    mode = "n";
    options.desc = "Go to previous diagnostic";
  }
  {
    key = "]d";
    action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
    mode = "n";
    options.desc = "Go to next diagnostic";
  }
  {
    key = "K";
    action = "<cmd>lua vim.lsp.buf.hover()<CR>";
    mode = "n";
    options.desc = "Show documentation for what is under cursor";
  }
  {
    key = "gD";
    action = "<cmd>lua vim.lsp.buf.declaration()<CR>";
    mode = "n";
    options.desc = "Go to declaration";
  }
  {
    key = "gd";
    action = "<cmd>lua vim.lsp.buf.definition()<CR>";
    mode = "n";
    options.desc = "Go to definition";
  }
  {
    key = "gi";
    action = "<cmd>lua vim.lsp.buf.implementation()<CR>";
    mode = "n";
    options.desc = "Go to implementation";
  }
  {
    key = "gr";
    action = "<cmd>lua vim.lsp.buf.references()<CR>";
    mode = "n";
    options.desc = "Find references";
  }
  {
    key = "<C-k>";
    action = "<cmd>lua vim.lsp.buf.signature_help()<CR>";
    mode = "n";
    options.desc = "Show signature help";
  }
  {
    key = "<leader>wa";
    action = "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>";
    mode = "n";
    options.desc = "Add workspace folder";
  }
  {
    key = "<leader>wr";
    action = "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>";
    mode = "n";
    options.desc = "Remove workspace folder";
  }
  {
    key = "<leader>wl";
    action = "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>";
    mode = "n";
    options.desc = "List workspace folders";
  }
  {
    key = "<leader>rs";
    action = "<cmd>LspRestart<CR>";
    mode = "n";
    options.desc = "Restart LSP";
  }
  {
    key = "<leader>rn";
    action = "<cmd>lua vim.lsp.buf.rename()<CR>";
    mode = "n";
    options.desc = "Rename symbol";
  }

  # Barbar keymaps
  {
    key = "<A-,>";
    action = "<Cmd>BufferPrevious<CR>";
    mode = "n";
    options.desc = "Previous buffer";
  }
  {
    key = "<A-.>";
    action = "<Cmd>BufferNext<CR>";
    mode = "n";
    options.desc = "Next buffer";
  }
  {
    key = "<A-<>";
    action = "<Cmd>BufferMovePrevious<CR>";
    mode = "n";
    options.desc = "Move buffer previous";
  }
  {
    key = "<A->>";
    action = "<Cmd>BufferMoveNext<CR>";
    mode = "n";
    options.desc = "Move buffer next";
  }
  {
    key = "<A-1>";
    action = "<Cmd>BufferGoto 1<CR>";
    mode = "n";
    options.desc = "Go to buffer 1";
  }
  {
    key = "<A-2>";
    action = "<Cmd>BufferGoto 2<CR>";
    mode = "n";
    options.desc = "Go to buffer 2";
  }
  {
    key = "<A-3>";
    action = "<Cmd>BufferGoto 3<CR>";
    mode = "n";
    options.desc = "Go to buffer 3";
  }
  {
    key = "<A-4>";
    action = "<Cmd>BufferGoto 4<CR>";
    mode = "n";
    options.desc = "Go to buffer 4";
  }
  {
    key = "<A-5>";
    action = "<Cmd>BufferGoto 5<CR>";
    mode = "n";
    options.desc = "Go to buffer 5";
  }
  {
    key = "<A-6>";
    action = "<Cmd>BufferGoto 6<CR>";
    mode = "n";
    options.desc = "Go to buffer 6";
  }
  {
    key = "<A-7>";
    action = "<Cmd>BufferGoto 7<CR>";
    mode = "n";
    options.desc = "Go to buffer 7";
  }
  {
    key = "<A-8>";
    action = "<Cmd>BufferGoto 8<CR>";
    mode = "n";
    options.desc = "Go to buffer 8";
  }
  {
    key = "<A-9>";
    action = "<Cmd>BufferGoto 9<CR>";
    mode = "n";
    options.desc = "Go to buffer 9";
  }
  {
    key = "<A-0>";
    action = "<Cmd>BufferLast<CR>";
    mode = "n";
    options.desc = "Go to last buffer";
  }
  {
    key = "<A-p>";
    action = "<Cmd>BufferPin<CR>";
    mode = "n";
    options.desc = "Pin/unpin buffer";
  }
  {
    key = "<A-c>";
    action = "<Cmd>BufferClose<CR>";
    mode = "n";
    options.desc = "Close buffer";
  }
  {
    key = "<C-p>";
    action = "<Cmd>BufferPick<CR>";
    mode = "n";
    options.desc = "Pick buffer";
  }
  {
    key = "<Space>bb";
    action = "<Cmd>BufferOrderByBufferNumber<CR>";
    mode = "n";
    options.desc = "Order by buffer number";
  }
  {
    key = "<Space>bn";
    action = "<Cmd>BufferOrderByName<CR>";
    mode = "n";
    options.desc = "Order by name";
  }
  {
    key = "<Space>bd";
    action = "<Cmd>BufferOrderByDirectory<CR>";
    mode = "n";
    options.desc = "Order by directory";
  }
  {
    key = "<Space>bl";
    action = "<Cmd>BufferOrderByLanguage<CR>";
    mode = "n";
    options.desc = "Order by language";
  }
  {
    key = "<Space>bw";
    action = "<Cmd>BufferOrderByWindowNumber<CR>";
    mode = "n";
    options.desc = "Order by window number";
  }

  # Telescope keymaps
  {
    key = "<leader>ff";
    action = "<cmd>lua require('telescope.builtin').find_files()<CR>";
    mode = "n";
    options.desc = "Telescope find files";
  }
  {
    key = "<leader>fg";
    action = "<cmd>lua require('telescope.builtin').live_grep()<CR>";
    mode = "n";
    options.desc = "Telescope live grep";
  }
  {
    key = "<leader>fb";
    action = "<cmd>lua require('telescope.builtin').buffers()<CR>";
    mode = "n";
    options.desc = "Telescope buffers";
  }
  {
    key = "<leader>fh";
    action = "<cmd>lua require('telescope.builtin').help_tags()<CR>";
    mode = "n";
    options.desc = "Telescope help tags";
  }

  # Oil keymap
  {
    key = "<leader>o";
    action = "<cmd>Oil<CR>";
    mode = "n";
    options.desc = "Open oil";
  }

  # Neogit keymap
  {
    key = "<leader>ng";
    action = "<cmd>Neogit<CR>";
    mode = "n";
    options.desc = "Neogit";
  }

  # Flash keymaps
  {
    key = "s";
    action = "<cmd>lua require('flash').jump()<CR>";
    mode = [
      "x"
      "o"
    ];
    options.desc = "Flash";
  }
  {
    key = "S";
    action = "<cmd>lua require('flash').treesitter()<CR>";
    mode = [
      "n"
      "x"
      "o"
    ];
    options.desc = "Flash Treesitter";
  }
  {
    key = "r";
    action = "<cmd>lua require('flash').remote()<CR>";
    mode = "o";
    options.desc = "Remote Flash";
  }
  {
    key = "R";
    action = "<cmd>lua require('flash').treesitter_search()<CR>";
    mode = [
      "o"
      "x"
    ];
    options.desc = "Treesitter Search";
  }
  {
    key = "<c-s>";
    action = "<cmd>lua require('flash').toggle()<CR>";
    mode = "c";
    options.desc = "Toggle Flash Search";
  }

  # Hlslens clear highlight
  {
    key = "<Leader>l";
    action = "<Cmd>noh<CR>";
    mode = "n";
    options = {
      noremap = true;
      silent = true;
    };
  }

  # Comment
  {
    key = "<C-/>";
    action = "<cmd>lua require('Comment.api').toggle.linewise.current()<CR><Esc>A";
    mode = [
      "n"
      "i"
    ];
    options.desc = "comment out line";
  }

  # Conform format toggle
  {
    key = "<C-F>";
    action = "<CMD>FormatToggle<CR>";
    mode = [
      "n"
      "i"
    ];
    options = {
      noremap = true;
      silent = true;
      desc = "toggle save format";
    };
  }

  # Treesj toggle
  {
    key = "<leader>m";
    action = "<cmd>TSJToggle<cr>";
    mode = "n";
    options.desc = "toggle node under cursor (split if one-line and join if multiline)";
  }

  # Skkeleton keymaps
  {
    key = "<C-j>";
    action = "<Plug>(skkeleton-enable)";
    mode = "i";
  }
  {
    key = "<C-j>";
    action = "<Plug>(skkeleton-enable)";
    mode = "c";
  }

  # in-and-out
  {
    key = "<C-CR>";
    action = "<cmd>lua require('in-and-out').in_and_out()<CR>";
    mode = "i";
  }

  # tiny-code-action
  {
    key = "<leader>ca";
    action = "<cmd>lua require('tiny-code-action').code_action()<CR>";
    mode = [
      "n"
      "v"
    ];
    options = {
      noremap = true;
      silent = true;
      desc = "See available code actions";
    };
  }

  # markdown-preview
  {
    key = "<leader>mp";
    action = "<cmd>MarkdownPreviewToggle<CR>";
    mode = "n";
    options.desc = "Toggle markdown preview";
  }
]
