# ランチャ。Hyprland の $menu と、クリップボード履歴の選択に使う。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.rofi = {
    programs.rofi.enable = true;
    home.file.".config/rofi" = {
      source = ../../../configs/rofi;
      recursive = true;
    };
  };

  flake.modules.nixos.rofi = {
    home-manager.sharedModules = [ hm.rofi ];
  };
}
