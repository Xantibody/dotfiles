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
  ".config/fish/config.fish" = {
    source = ../../../fish/config.fish;
  };
}
