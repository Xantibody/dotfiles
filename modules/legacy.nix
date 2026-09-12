# 機能ごとのファイルへまだ切り出していない設定。
# modules/_legacy/ が空になった時点でこのファイルごと消える。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.legacy = ./_legacy/home-manager;
  flake.modules.homeManager.legacy-linux = ./_legacy/home-manager/linux.nix;

  flake.modules.darwin.legacy =
    { config, ... }:
    {
      imports = [ ./_legacy/darwin ];
      # launchd.nix と system.nix がまだ username を module 引数で受け取っている
      _module.args.username = config.my.user.name;
      home-manager.sharedModules = [ hm.legacy ];
    };

  flake.modules.nixos.legacy = {
    imports = [
      ./_legacy/nixos
      ./_legacy/nixos/hardware-configuration.nix
    ];
    home-manager.sharedModules = [
      hm.legacy
      hm.legacy-linux
    ];
  };
}
