{ pkgs, ... }:
let
  username = "raizawa";
in
{
  home = import ./home { inherit pkgs username; };
  programs = import ./programs { inherit pkgs; };
  wayland = import ./wayland.nix;
  services = import ./services.nix;
}
