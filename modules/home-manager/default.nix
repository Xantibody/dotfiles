{ pkgs, username, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home = import ./home { inherit pkgs username isLinux; };
  programs = import ./programs { inherit pkgs isLinux; };
  wayland = import ./wayland.nix { inherit isLinux; };
  services = import ./services.nix { inherit isLinux; };
}
