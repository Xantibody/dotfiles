{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  lib = pkgs.lib;
in
{
  home = import ./home {
    inherit
      pkgs
      lib
      homeDirectory
      username
      isLinux
      self
      ;
  };
  programs = import ./programs { inherit pkgs lib isLinux; };
}
// lib.optionalAttrs isLinux {
  wayland = import ./wayland.nix;
  services = import ./services;
}
