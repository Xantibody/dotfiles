{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
  mcp = import ./mcp.nix { inherit pkgs; };
in
with pkgs;
(
  [
    bat

    obsidian
    cargo
    deck
    direnv
    devbox
    eza
    fd

    gh
    gnumake
    google-chrome
    iccheck
    nix-prefetch-github
    ripgrep
    rustc
    uv
    just
    vhs
    edge.claude-code
    codex
    gemini-cli
    yaskkserv2
    discord-ptb
  ]
  ++ k8s
  ++ mcp
)
