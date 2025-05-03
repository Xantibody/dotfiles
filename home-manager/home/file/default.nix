{ pkgs, ... }:
{
  ".config/nvim/init.lua" = {
    source = ../../../nvim/init.lua;
  };
  ".config/nvim/lua" = {
    source = ../../../nvim/lua;
    recursive = true;
  };
  ".config/nvim/fplugin" = {
    source = ../../../nvim/fplugin;
    recursive = true;
  };
  # ".config/alacritty/alacritty.toml" = {
  #   source = ../../../alacritty/alacritty.toml;
  # };
  # ".config/alacritty/themes/themes/dawnfox.toml" = {
  #   source = "${pkgs.alacritty-theme}/dawnfox.toml";
  # };
  ".config/fish/config.fish" = {
    source = ../../../fish/config.fish;
  };
}
