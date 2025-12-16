{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  system = pkgs.stdenv.hostPlatform.system;
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
  programs = import ./programs {
    inherit
      pkgs
      lib
      isLinux
      isDarwin
      ;
  };
}
// lib.optionalAttrs isLinux {
  wayland = import ./wayland.nix;
  services = import ./services;
}
