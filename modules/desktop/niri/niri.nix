# niri。Hyprland と並べて入れ、SDDM のセッション選択で切り替える。
# 設定は niri 同梱の既定値を、このマシンにある道具 (kitty, rofi, hyprlock) に差し替えて使う。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.niri =
    { pkgs, ... }:
    {
      xdg.configFile."niri/config.kdl".source = pkgs.runCommand "niri-config.kdl" { } ''
        substitute ${pkgs.niri.src}/resources/default-config.kdl $out \
          --replace-fail '"alacritty"' '"kitty"' \
          --replace-fail 'Terminal: alacritty' 'Terminal: kitty' \
          --replace-fail '{ spawn "fuzzel"; }' '{ spawn "rofi" "-show" "drun"; }' \
          --replace-fail 'Application: fuzzel' 'Application: rofi' \
          --replace-fail '"swaylock"' '"hyprlock"' \
          --replace-fail 'Screen: swaylock' 'Screen: hyprlock' \
          --replace-fail 'spawn-at-startup "waybar"' '// waybar は systemd の user service が起こす'
      '';
    };

  flake.modules.nixos.niri = {
    # niri.desktop を wayland-sessions に置き、niri-session が graphical-session.target を張る
    programs.niri.enable = true;

    home-manager.sharedModules = [ hm.niri ];
  };
}
