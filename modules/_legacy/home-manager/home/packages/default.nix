{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
  profile = import ./profile.nix { inherit pkgs; };
  darwin = import ./darwin.nix { inherit pkgs; };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
with pkgs;
(
  [
    bat
    cargo
    deck
    direnv
    duckdb
    discord-ptb
    eza
    fd
    gnumake
    go
    gopls
    iccheck
    nix-prefetch-github
    obsidian
    ripgrep
    # tsgo-lsp プラグインが PATH 上の tsgo を起動する (typescript 7 系は tsc と tsgo を同梱)
    typescript
    vhs
    yaskkserv2
  ]
  ++ k8s
  ++ profile
  ++ pkgs.lib.optionals isDarwin darwin
)
