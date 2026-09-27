# 画面上端のステータスバー。設定は configs/waybar/ にある jsonc と css。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.waybar = {
    programs.waybar = {
      enable = true;
      # exec-once で起動すると、pipewire-pulse より先に立ち上がった回に pulseaudio
      # モジュールが接続失敗の例外で abort し、バーが消えたままになる。systemd なら
      # セッションの準備を待ち、落ちても再起動される
      systemd.enable = true;
    };
    home.file.".config/waybar" = {
      source = ../../../configs/waybar;
      recursive = true;
    };
  };

  flake.modules.nixos.waybar = {
    home-manager.sharedModules = [ hm.waybar ];
  };
}
