# 機能と呼べるほどの設定を持たない、素の開発用 CLI。
# 設定や他クラスの配線を伴うものは自分のファイルを持つので、ここには残らない。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    nixpkgs.overlays = [
      (import ../../overlays/iccheck.nix)
      (import ../../overlays/deck.nix)
    ];
    home-manager.sharedModules = [ hm.dev-cli ];
  };
in
{
  flake.modules.homeManager.dev-cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cargo
        deck
        duckdb
        gnumake
        go
        gopls
        iccheck
        nix-prefetch-github
        ripgrep
        # tsgo-lsp プラグインが PATH 上の tsgo を起動する (typescript 7 系は tsc と tsgo を同梱)
        typescript
        vhs
      ];
    };

  flake.modules.darwin.dev-cli = share;

  flake.modules.nixos.dev-cli =
    { pkgs, ... }:
    {
      imports = [ share ];
      # NixOS には macOS と違って素の Unix ツールが揃っていないので system 側にも置く
      environment.systemPackages = with pkgs; [
        gcc
        unzip
        coreutils
        gawk
      ];
    };
}
