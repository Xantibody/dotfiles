# キーマップ設定 (LSP keymapsは edit/lsp/ に移動済み)
{
  keymaps = [
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
  ];
}
