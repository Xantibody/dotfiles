{ config, pkgs, inputs, ... }:


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
      ripgrep
      discord
      gnumake
    ];
  };
  programs = {
    git = {
      enable = true;
      userName = "Xantibody";
      userEmail = "zeku.bushinryu38@gmail.com";
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
  programs{
    kitty{
      enable = true; # required for the default Hyprland config
    }
  }
  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        # example settings
        settings = {
          "$mod" = "SUPER";
          bind =
            [
              "$mod, F, exec, firefox"
              ", Print, exec, grimblast copy area"
            ]
            ++ (
              # workspaces
              # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
              builtins.concatLists (builtins.genList (i:
                  let ws = i + 1;
                  in [
                    "$mod, code:1${toString i}, workspace, ${toString ws}"
                    "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                  ]
                )
                9)
            );
        };
      };
    };
  };
}
