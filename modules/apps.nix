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

  flake.modules.darwin.apps =
    { pkgs, ... }:
    {
      # brew cask の Chrome は上流の url が版ごとに動くので、hash を固定した src に差し替える
      nixpkgs.overlays = [ (import ../overlays/brew-casks.nix) ];
      environment.systemPackages = [
        # _1password-gui  # 1Password は Homebrew cask を手動導入したため一旦コメントアウト
        # brewCasks.claude  # Claude は Homebrew cask を手動導入したため一旦コメントアウト
        pkgs.google-chrome
      ];
      home-manager.sharedModules = [
        hm.apps
        hm.apps-darwin
      ];
    };

  flake.modules.nixos.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gimp3
        slack
      ];
      home-manager.sharedModules = [ hm.apps ];
    };
}
