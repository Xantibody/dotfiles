{ pkgs, ... }:
with pkgs;
[
  pympress
  google-chrome
  bat
  devbox
  explex
  explex-nf
  eza
  fzf
  fishPlugins.z
  gh

  #  gnupg
  gnumake
  nix-prefetch-github
  ripgrep
  zellij
  iccheck
]
