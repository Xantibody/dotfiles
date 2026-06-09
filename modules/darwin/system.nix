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
    activationScripts.postActivation.text = ''
      sudo -u ${username} ${pkgs.defaultbrowser}/bin/defaultbrowser zen
    '';
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
          # 1Password 連携のため /Applications/Nix Apps/ 版 (署名保持コピー) を pin する。
          # Home Manager Apps / trampoline 版は /nix/store 解決 or ad-hoc 署名で 1Password に弾かれる。
          { app = "/Applications/Nix Apps/Zen Browser (Beta).app"; }
          { app = "${pkgs.kitty}/Applications/kitty.app"; }
        ];
      };
    };
  };
}
