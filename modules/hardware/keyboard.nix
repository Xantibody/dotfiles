# 自作キーボード。QMK のファーム書き込みと、VIA のレイアウト設定。
# CapsLock と Ctrl+H の入れ替えは OS 側 (xremap) が受け持つ。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.keyboard = {
    home.file.".via/via.json".source = ../../configs/via/via.json;
  };

  flake.modules.nixos.keyboard =
    { pkgs, ... }:
    {
      # qmk-udev-rules はこれが入れる
      hardware.keyboard.qmk.enable = true;

      environment.systemPackages = [ pkgs.via ];
      home-manager.sharedModules = [ hm.keyboard ];
    };
}
