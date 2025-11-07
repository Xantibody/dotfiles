{ pkgs, ... }:
with pkgs;
[
  bat

  ## k8s
  kustomize
  kubernetes-helm
  yq-go
  dyff
  kubeconform
  kubernetes-helm
  k9s

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
