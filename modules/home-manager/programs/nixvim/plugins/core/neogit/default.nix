# Neogit Gitクライアント
{ pkgs, ... }:
{
  plugins.neogit.enable = true;

  # Neogit keymap
  keymaps = [
    {
      key = "<leader>ng";
      action = "<cmd>Neogit<CR>";
      mode = "n";
      options.desc = "Neogit";
    }
  ];
}
