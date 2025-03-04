{ config, pkgs, ... }:

  {
    home.username = "raziawa";
    home.homeDirectory = "/home/raizawa";
    home.stateVersion = "24.11";
    home.file  = {
        ".config/nvim/init.lua" = {
          source = /home/raizawa/Repo/dotfiles/nvim/init.lua;
      };
        ".config/nvim/lua" = {
          source = /home/raizawa/Repo/dotfiles/nvim/lua;
          recursive = true;
      };
        ".config/nvim/fplugin" = {
          source = /home/raizawa/Repo/dotfiles/nvim/fplugin;
          recursive = true;
      };
        ".config/tumx/tmux.conf" = {
          source = /home/raizawa/Repo/dotfiles/tmux/tmux.conf;
      };
        ".config/alacritty/alacritty.toml" = {
          source = /home/raizawa/Repo/dotfiles/alacritty/alacritty.toml;
      };
        ".config/fish/config.fish" = {
          source = /home/raizawa/Repo/dotfiles/fish/config.fish;
      };
      
    };
      shell = pkgs.fish;
  };
