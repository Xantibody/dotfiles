# Hyprland。WM 本体と、その上で動く常駐・クリップボード・ランチャ。
# 常駐 (waybar, cliphist, yaskkserv2 など) は各機能が systemd の user service として持つ。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.hyprland =
    { lib, pkgs, ... }:
    {
      wayland.windowManager.hyprland = {
        enable = true;
        # 本体と portal は NixOS の programs.hyprland が入れる。ここで持つと別の版が
        # 並びうるので、home-manager は設定ファイルだけを書く
        package = null;
        portalPackage = null;
        # graphical-session.target は UWSM が張る。home-manager 側の
        # hyprland-session.target と二重にしない
        systemd.enable = false;
        # home.stateVersion 24.11 の既定値を明示する (26.05 以降の既定は lua)
        configType = "hyprlang";
        settings = {
          "$mod" = "SUPER";
          "$terminal" = "kitty";
          "$fileManager" = "dolphin";
          "$menu" = "rofi -modi drun,run -show drun";
          bind = [
            "$mod, Q, exec, $terminal"
            "$mod, C, killactive,"
            "$mod, M, exit,"
            "$mod, E, exec, $fileManager"
            # zen-browser-flake の beta が入れるコマンドは zen-beta で、zen は存在しない
            "$mod, F, exec, zen-beta"
            "$mod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
            "$mod, R, exec, $menu"
            "$mod, P, pseudo, # dwindle"
            "$mod, S, layoutmsg, togglesplit # dwindle"
            "$mod_SHIFT, E, exec, emacs"

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
          xwayland = {
            force_zero_scaling = true;
          };
          monitor = [
            "eDP-1, preferred, auto, 1"
            # ", preferred, auto,1, mirror, eDP-1"
          ];
        };
      };

      services.hyprpaper.enable = true;

      # クリップボード履歴。$mod+V の rofi から選ぶ
      services.cliphist = {
        enable = true;
        allowImages = true;
      };
      # 履歴が無限に溜まるので、セッションを始めるたびに消す
      systemd.user.services.cliphist.Service.ExecStartPre = "${lib.getExe pkgs.cliphist} wipe";
    };

  flake.modules.nixos.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # PAM の hyprlock サービスもこれが作る
      programs.hyprlock.enable = true;

      programs.hyprland = {
        enable = true;
        # セッションを systemd の graphical-session.target に載せる。waybar などの
        # user service はこれを待って起動する
        withUWSM = true;
      };

      # ログイン画面。X11 と LightDM は Hyprland に要らないので載せない
      # (services.xserver.enable は既定で LightDM を起こしていた)。
      # --cmd に uwsm start <id> と書くと greetd の環境で .desktop を探せるかに依存するので、
      # store パスで Exec が埋まった session 一覧を渡して選ばせ、以後は記憶させる
      services.greetd = {
        enable = true;
        settings.default_session.command = lib.concatStringsSep " " [
          "${lib.getExe pkgs.tuigreet}"
          "--time"
          "--remember"
          "--remember-session"
          "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
        ];
      };

      # Slack・Discord・Obsidian などの Electron を XWayland でなく Wayland で動かす。
      # XWayland だと拡大時にぼやけ、IME も通らない
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      environment.systemPackages = with pkgs; [
        wl-clipboard
        libnotify
        brightnessctl
        playerctl
        kdePackages.dolphin
      ];

      home-manager.sharedModules = [ hm.hyprland ];
    };
}
