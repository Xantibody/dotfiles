# コアプラグイン: treesitter, telescope, oil, neogit, gitsigns, barbar, hlchunk
{ pkgs, ... }:
{
  # Mini icons
  plugins.mini = {
    enable = true;
    modules.icons = { };
  };

  # Web devicons
  plugins.web-devicons.enable = true;
}
