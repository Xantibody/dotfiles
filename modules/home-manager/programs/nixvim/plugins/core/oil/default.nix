# Oil ファイルマネージャー
{ pkgs, ... }:
{
  plugins.oil = {
    enable = true;
    settings = {
      default_file_explorer = true;
      view_options.show_hidden = true;
    };
  };

  # Oil keymap
  keymaps = [
    {
      key = "<leader>o";
      action = "<cmd>Oil<CR>";
      mode = "n";
      options.desc = "Open oil";
    }
  ];
}
