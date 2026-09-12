# 画面上端のステータスバー。設定は configs/waybar/ にある jsonc と css。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.waybar = {
    programs.waybar.enable = true;
    home.file.".config/waybar" = {
      source = ../../../configs/waybar;
      recursive = true;
    };
  };

  flake.modules.nixos.waybar =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.waybar ];
      home-manager.sharedModules = [ hm.waybar ];
    };
}
