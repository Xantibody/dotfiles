# デスクトップ通知。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.notifications = {
    services.mako = {
      enable = true;
      settings = {
        icons = true;
        markup = true;
        default-timeout = 5000;
      };
    };
  };

  flake.modules.nixos.notifications = {
    home-manager.sharedModules = [ hm.notifications ];
  };
}
