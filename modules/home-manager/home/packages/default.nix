{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
in
with pkgs;
[
  bat

  awscli2
  obsidian
  cargo
  deck
  devenv
  direnv
  devbox
  eza
  fd
  fnm
  gh
  gnumake
  google-chrome
  iccheck
  nix-prefetch-github
  pympress
  ripgrep
  rustc
  uv
  just
  vhs
  edge.claude-code
  codex
  gemini-cli
  context7-mcp
  serena
  github-mcp-server
  yaskkserv2
]
++ k8s
