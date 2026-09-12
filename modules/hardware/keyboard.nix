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
      hardware.keyboard.qmk.enable = true;

      services.udev = {
        enable = true;
        packages = [ pkgs.qmk-udev-rules ];
        extraRules = ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="10a5", ATTR{idProduct}=="d805", MODE="0666"
        '';
      };

      environment.systemPackages = [ pkgs.via ];
      home-manager.sharedModules = [ hm.keyboard ];
    };
}
