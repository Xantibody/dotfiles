{ config, pkgs, inputs, ... }:{
  imports = [
    inputs.hyprpanel.homeManagerModules.hyprpanel
  ];

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
    hyprpanel = {
      enable = true;
      overwrite.enable = true;
      hyprland.enable = true;
      theme = "catppuccin_mocha";
      layout = {
        "bar.layouts" =
          let
            layout = { showBattery ? true }: {
              "left" = [
                "dashboard"
                "workspaces"
                "windowtitle"
                "updates"
                "storage"
              ] ++ (if showBattery then [ "battery" ] else [ ]);
              "middle" = [
                "media"
              ];
              "right" = [
                "cpu"
                "ram"
                "volume"
                "network"
                "bluetooth"
                "systray"
                "clock"
                "notifications"
              ];
            };
            none = {
              "left" = [ ];
              "middle" = [ ];
              "right" = [ ];
            };
          in
          {
            "0" = layout { };
            "1" = none;
            "2" = layout { showBattery = false; };
            "3" = none;
          };
      };
      settings = {
        bar.customModules.updates.pollingInterval = 1440000;
        theme.bar.floating = false;
        theme.bar.buttons.enableBorders = true;
        theme.bar.transparent = true;
        theme.font.size = "14px";
        menus.clock.time.military = true;
        menus.clock.time.hideSeconds = false;
        bar.clock.format = "%y/%m/%d  %H:%M";
        bar.media.show_active_only = true;
        bar.notifications.show_total = false;
        theme.bar.buttons.modules.ram.enableBorder = false;
        bar.launcher.autoDetectIcon = true;
        bar.battery.hideLabelWhenFull = true;
        menus.dashboard.controls.enabled = false;
        menus.dashboard.shortcuts.enabled = true;
        menus.clock.weather.enabled = false;
        menus.dashboard.shortcuts.right.shortcut1.command = "gcolor3";
        menus.media.displayTime = true;
        menus.power.lowBatteryNotification = true;
        bar.customModules.updates.updateCommand = "jq '[.[].cvssv3_basescore | to_entries | add | select(.value > 5)] | length' <<< $(vulnix -S --json)";
        bar.customModules.updates.icon.updated = "󰋼";
        bar.customModules.updates.icon.pending = "󰋼";
        bar.volume.rightClick = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        bar.volume.middleClick = "pavucontrol";
        bar.media.format = "{title}";
      };
    };
  };
}
