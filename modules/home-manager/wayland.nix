{ isLinux, ... }:
{
  windowManager = {
    hyprland = {
      enable = isLinux;
      settings = {
        exec-once = [
          # 履歴が無限に消えないので起動時に消す
          "cliphist wipe"
          "wl-paste --type text --watch cliphist store # Stores only text data"
          "wl-paste --type image --watch cliphist store # Stores only image data"
          "waybar"
        ];
        "$mod" = "SUPER";
        "$terminal" = "alacritty";
        "$fileManager" = "dolphin";
        "$menu" = "rofi -modi drun,run -show drun";
        bind = [
          "$mod, Q, exec, $terminal"
          "$mod, C, killactive,"
          "$mod, M, exit,"
          "$mod, E, exec, $fileManager"
          # "$mod, F, exec, firefox"
          "$mod, F, exec, google-chrome-stable"
          "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
          "$mod, R, exec, $menu"
          "$mod, P, pseudo, # dwindle"
          "$mod, S, togglesplit, # dwindle"

          # Move focus with mod for vim key
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"
          "$mod_SHIFT, H, swapwindow, l"
          "$mod_SHIFT, L, swapwindow, r"
          "$mod_SHIFT, K, swapwindow, u"
          "$mod_SHIFT, J, swapwindow, d"

        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1;
              in
              [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
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
        monitor = [
          "eDP-1, preferred, auto, 1"
          "eDP-2, preferred, auto-up, 1"
        ];
      };
    };
  };
}
