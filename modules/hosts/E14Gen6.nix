# ThinkPad E14 Gen6 (NixOS)。
{ config, lib, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  my.hosts.nixos = [ "E14Gen6" ];

  flake.modules.nixos.E14Gen6 = {
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
      "mdsf"
      "git"
      "claude"
      "agents"
      "user"
      "nixpkgs"
      "home-manager"
      "comma"
      "neovim"
      "sops"
      "legacy"
    ] nixos;

    my.user = {
      name = "raizawa";
      home = "/home/raizawa";
    };
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "24.11";
  };
}
