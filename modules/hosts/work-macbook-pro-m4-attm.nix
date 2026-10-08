# 会社支給の MacBook Pro (M4)。私物との違いはこのファイルだけを見れば分かる:
# 会社用の git 設定 (sops で復号)、会議用アプリ、Zen に載せる kotdiff。
{
  config,
  lib,
  inputs,
  ...
}:
let
  darwin = config.flake.modules.darwin;
in
{
  my.hosts.darwin = [ "work-macbook-pro-m4-attm" ];

  flake.modules.darwin.work-macbook-pro-m4-attm =
    { pkgs, ... }:
    {
      imports = lib.attrVals [
        "nix"
        "fish"
        "fzf"
        "prompt"
        "kitty"
        "felis"
        "k8s"
        "dev-cli"
        "apps"
        "profiling"
        "emacs"
        "skk"
        "clipboard"
        "dock"
        "keyboard"
        "omniwm"
        "finder"
        "touchid"
        "fonts"
        "arto"
        "mdsf"
        "git"
        "ha"
        "claude"
        "agents"
        "user"
        "nixpkgs"
        "home-manager"
        "spotlight"
        "comma"
        "neovim"
        "zen"
        "magical-merchant"
        "sops"
        "work-git"
      ] darwin;

      my.user = {
        name = "r-aizawa";
        home = "/Users/r-aizawa";
      };
      nixpkgs.hostPlatform = "aarch64-darwin";
      system.stateVersion = 4;

      # MeetingBar は ad-hoc 署名なので、カレンダーの許可を rebuild 越しに残すため再署名する
      # AIDEV-NOTE: zoom も ad-hoc 署名だが、Frameworks/AnnoUI.bundle の Info.plist に
      # CFBundleIdentifier が無く、stabilizeApp の rcodesign が止まるので素のまま入れる
      environment.systemPackages = [
        ((pkgs.callPackage inputs.nix-mac-app-identity { }).stabilizeApp pkgs.meetingbar)
        pkgs.zoom-us
      ];

      home-manager.sharedModules = [
        {
          programs.zen-browser.profiles.r-aizawa.extensions.packages = [
            inputs.kotdiff.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        }
      ];
    };
}
