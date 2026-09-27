# Super+Space で開く which-key 風のメニュー。キーを 1 つずつ押して下の階層へ進み、
# 末端でコマンドを実行する。Hyprland の bind とは別の木なので、よく使うものだけを置く。
# 色は Stylix のスキームから取る (wlr-which-key には Stylix の target が無い)。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.which-key =
    { config, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;
      waybarScript = name: "~/.config/waybar/scripts/${name}";
    in
    {
      programs.wlr-which-key = {
        enable = true;
        settings = {
          font = "${config.stylix.fonts.monospace.name} 12";
          background = "${c.base00}e6";
          color = c.base05;
          border = c.base0A;
          separator = " ➜ ";
          border_width = 2;
          corner_r = 10;
          anchor = "center";
          # 押したキーが Hyprland の bind に食われないようにする
          inhibit_compositor_keyboard_shortcuts = true;

          menu = [
            {
              key = "a";
              desc = "Apps";
              submenu = [
                {
                  key = "t";
                  desc = "Terminal (kitty)";
                  cmd = "kitty";
                }
                {
                  key = "b";
                  desc = "Browser (Zen)";
                  cmd = "zen-beta";
                }
                {
                  key = "e";
                  desc = "Emacs";
                  cmd = "emacs";
                }
                {
                  key = "f";
                  desc = "Files (Dolphin)";
                  cmd = "dolphin";
                }
              ];
            }
            {
              key = "r";
              desc = "Launcher";
              cmd = "rofi -modi drun,run -show drun";
            }
            {
              key = "v";
              desc = "Clipboard history";
              cmd = "cliphist list | rofi -dmenu | cliphist decode | wl-copy";
            }
            {
              key = "w";
              desc = "Window";
              submenu = [
                {
                  key = "c";
                  desc = "Close";
                  cmd = "hyprctl dispatch killactive";
                }
                {
                  key = "f";
                  desc = "Fullscreen";
                  cmd = "hyprctl dispatch fullscreen";
                }
                {
                  key = "t";
                  desc = "Toggle floating";
                  cmd = "hyprctl dispatch togglefloating";
                }
                {
                  key = "s";
                  desc = "Toggle split";
                  cmd = "hyprctl dispatch layoutmsg togglesplit";
                }
              ];
            }
            {
              key = "i";
              desc = "System info";
              cmd = "sysinfo";
            }
            {
              key = "n";
              desc = "Network";
              submenu = [
                {
                  key = "w";
                  desc = "Wi-Fi";
                  cmd = waybarScript "wifi-menu.sh";
                }
                {
                  key = "b";
                  desc = "Bluetooth";
                  cmd = waybarScript "bluetooth-menu.sh";
                }
              ];
            }
            {
              key = "p";
              desc = "Power";
              submenu = [
                {
                  key = "l";
                  desc = "Lock";
                  cmd = "loginctl lock-session";
                }
                {
                  key = "s";
                  desc = "Suspend";
                  cmd = "systemctl suspend";
                }
                {
                  key = "r";
                  desc = "Reboot";
                  cmd = "systemctl reboot";
                }
                {
                  key = "o";
                  desc = "Power off";
                  cmd = "systemctl poweroff";
                }
                {
                  key = "e";
                  desc = "Log out";
                  cmd = "uwsm stop";
                }
              ];
            }
          ];
        };
      };

      wayland.windowManager.hyprland.settings.bind = [ "$mod, Space, exec, wlr-which-key" ];
    };

  flake.modules.nixos.which-key = {
    home-manager.sharedModules = [ hm.which-key ];
  };
}
