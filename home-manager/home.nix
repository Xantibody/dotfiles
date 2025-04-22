{
  nixpkgs,
  system,
  hyprpanel,
  ... 
}:
  let
    lib = nixpkgs.lib;
    pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true; # プロプライエタリなパッケージを許可
    };
  in
{
  nixpkgs.overlays = [
    hyprpanel.overlay
  ];
  imports = [
    hyprpanel.homeManagerModules.hyprpanel
  ];
  home = rec {
    username = "raizawa";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
    file  = {
        ".config/nvim/init.lua" = {
          source = ../nvim/init.lua;
      };
        ".config/nvim/lua" = {
          source = ../nvim/lua;
          recursive = true;
      };
        ".config/nvim/fplugin" = {
          source = ../nvim/fplugin;
          recursive = true;
      };
        ".config/alacritty/alacritty.toml" = {
          source = ../alacritty/alacritty.toml;
      };
        ".config/alacritty/themes/themes/dawnfox.toml" = {
          source = "${pkgs.alacritty-theme}/dawnfox.toml";
      };
        ".config/fish/config.fish" = {
          source = ../fish/config.fish;
      };
    };

    packages = with pkgs; [
      bat
      eza
      alacritty-theme
      ripgrep
      discord
      gnumake
      wl-clipboard
      cliphist
      fzf

(buildGoModule {
      pname = "iccheck";
      version = "0.9.0";
      src = fetchFromGitHub {
        owner = "salab";
        repo = "iccheck";
        rev = "v0.9.0";
        sha256 = "sha256-2bD5gN/7C79njrCVoR5H2ses6pWAQHZcYj7/f2+Ui/o=";
      };
      vendorHash = "sha256-pqjtoshoQlz+SFpaaxN3GMaDdZ+ztiIV6w+CTrRHuaA=";
      meta = with lib; {
        homepage = "https://github.com/salab/iccheck";
      };
      doCheck = false;
      subPackages = [
        "."
        "./cmd"
        "./pkg/domain"
        "./pkg/fleccs"
        "./pkg/lsp"
        "./pkg/ncdsearch"
        "./pkg/printer"
        "./pkg/search"
        "./pkg/utils"
      ];
    })
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
        biome
        nodejs_23

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

  wayland = {
    windowManager = {
      hyprland = {
        enable = true;
        settings = {
          exec-once = [
            "fcitx5"
            "wl-paste --type text --watch cliphist store # Stores only text data"
            "wl-paste --type image --watch cliphist store # Stores only image data"
          ];
          "$mod" = "SUPER";
          "$terminal" = "alacritty";
          "$fileManager" = "dolphin";
          "$menu" = "wofi --show drun";
          bind = [
            "$mod, Q, exec, $terminal"
            "$mod, C, killactive,"
            "$mod, M, exit,"
            "$mod, E, exec, $fileManager"
            "$mod, F, exec, firefox"
            "$mod, V, exec, cliphist list | wofi -S dmenu | cliphist decode | wl-copy"
            "$mod, R, exec, $menu"
            "$mod, P, pseudo, # dwindle"
            "$mod, S, togglesplit, # dwindle"

            # Move focus with mod + arrow keys
            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"
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
          input = {
            repeat_delay = 250;
            repeat_rate = 50;
            kb_layout = "us";
            # kb_variant =
            # kb_model =
            # kb_options =
            # kb_rules =
            follow_mouse = 1;

            sensitivity = 0;
            touchpad.natural_scroll = true; 
          };
          # xwayland = {
          #   force_zero_scaling = true;
          # };
          monitor = "eDP-1, preferred, auto, 1";
        };
      };
    };
  }; 
}
