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
          # 1Password 連携のため /Applications/Nix Apps/ 版 (署名保持コピー) を pin する。
          # Home Manager Apps / trampoline 版は /nix/store 解決 or ad-hoc 署名で 1Password に弾かれる。
          { app = "/Applications/Nix Apps/Zen Browser (Beta).app"; }
          { app = "${pkgs.kitty}/Applications/kitty.app"; }
          { app = "${pkgs.magical-merchant}/Applications/Magical Merchant.app"; }
          # 常駐 pin と「起動中なだけの app」の境目。show-recents = false だと
          # macOS は両者の間に区切り線を描かないので、spacer tile を末尾に
          # 置いて自前で区切る。
          {
            spacer = {
              small = true;
            };
          }
        ];
      };
    };
  };
}
