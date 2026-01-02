{
  pkgs,
  username,
  zen-browser,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  system = {
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
        NSWindowShouldDragOnGesture = true;
      };
      dock = {
        show-recents = false;
        autohide = true;
        persistent-apps = [
          { app = "${pkgs.slack}/Applications/slack.app/"; }
          {
            spacer = {
              small = true;
            };
          }
          { app = "/Users/${username}/Applications/Home Manager Apps/Zen Browser (Beta).app"; }
          { app = "${pkgs.kitty}/Applications/kitty.app"; }
        ];
      };
    };
  };
}
