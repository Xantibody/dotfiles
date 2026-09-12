# 設定を Nix で持っていない GUI アプリ。入れているだけ。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        discord-ptb
        obsidian
      ];
    };

  # Linux 版は nixos 側の environment.systemPackages に入っている
  flake.modules.homeManager.apps-darwin =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.slack ];
    };

  flake.modules.darwin.apps = {
    home-manager.sharedModules = [
      hm.apps
      hm.apps-darwin
    ];
  };
  flake.modules.nixos.apps = {
    home-manager.sharedModules = [ hm.apps ];
  };
}
