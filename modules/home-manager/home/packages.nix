{ pkgs, ... }:
with pkgs;
[
  bat
  kustomize
  kubernetes-helm
  yq-go
  dyff
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
  # github-mcp-server
  yaskkserv2
]
