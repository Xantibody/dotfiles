# コアプラグイン: treesitter, telescope, oil, neogit, gitsigns, barbar, hlchunk
{ pkgs, ... }:
{
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
