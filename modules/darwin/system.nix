{ pkgs, username, ... }:
{
  stateVersion = 4;
  primaryUser = username;
  keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
  defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };
    dock = {
      show-recents = false;
      autohide = true;
      persistent-apps = [
        { app = "/System/Applications/Launchpad.app"; }
        { app = "${pkgs.slack}/Applications/slack.app/"; }
        { app = "${pkgs.google-chrome}/Applications/Google Chrome.app"; }
        {
          spacer = {
            small = true;
          };
        }
        { app = "${pkgs.kitty}/Applications/kitty.app"; }
      ];
    };
  };
}
