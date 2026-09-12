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
        "k8s"
        "dev-cli"
        "apps"
        "profiling"
        "emacs"
        "skk"
        "clipboard"
        "mdsf"
        "git"
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
        "legacy"
      ] darwin;

      my.user = {
        name = "r-aizawa";
        home = "/Users/r-aizawa";
      };
      nixpkgs.hostPlatform = "aarch64-darwin";

      environment.systemPackages = with pkgs; [
        meetingbar
        zoom-us
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
