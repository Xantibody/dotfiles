{ config, pkgs, ... }:


  {
    home.username = "raizawa";
    home.homeDirectory = "/home/raizawa";
    home.stateVersion = "24.11";
    home.file  = {
        ".config/nvim/init.lua" = {
          source = ./nvim/init.lua;
      };
        ".config/nvim/lua" = {
          source = ./nvim/lua;
          recursive = true;
      };
        ".config/nvim/fplugin" = {
          source = ./nvim/fplugin;
          recursive = true;
      };
        ".config/tumx/tmux.conf" = {
          source = ./tmux/tmux.conf;
      };
        ".config/alacritty/alacritty.toml" = {
          source = ./alacritty/alacritty.toml;
      };
        ".config/fish/config.fish" = {
          source = ./fish/config.fish;
      };
      
    };
  }
