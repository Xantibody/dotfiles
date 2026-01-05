# Neogit Gitクライアント
{ pkgs, ... }:
{
  plugins.neogit = {
    enable = true;
    settings.integrations.diffview = true;
  };

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
