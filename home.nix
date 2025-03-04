{ config, pkgs, ... }:


{
  home = rec {
    username = "raizawa";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
    file  = {
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
        ".config/alacritty/themes/themes/dawnfox.toml" = {
          source = "${pkgs.alacritty-theme}/dawnfox.toml";
      };
        ".config/fish/config.fish" = {
          source = ./fish/config.fish;
      };
    };
    packages = with pkgs; [
      bat
      eza
      alacritty-theme
    ];
  };
  programs = {
    git = {
      enable = true;
      userName = "Xantibody";
      userEmail = "Zeku.bushinryu38@gmail.com";
    };

    neovim = {
      enable = true;
      defaultEditor = true; # $EDITOR=nvimに設定
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs; [
        ripgrep
        biome
        
        #LSP
        rust-analyzer
        efm-langserver
        lua-language-server
      ];
    };
  };
}
