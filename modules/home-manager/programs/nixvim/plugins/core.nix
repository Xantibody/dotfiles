# コアプラグイン: treesitter, telescope, oil, neogit, gitsigns, barbar, hlchunk
{ pkgs, ... }:
{
  # Barbar
  plugins.barbar.enable = true;

  # Which-key
  plugins.which-key.enable = true;

  # fzf-lua
  plugins.fzf-lua.enable = true;

  # Mini icons
  plugins.mini = {
    enable = true;
    modules.icons = { };
  };

  # Web devicons
  plugins.web-devicons.enable = true;
}
