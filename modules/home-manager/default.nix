{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  system = pkgs.stdenv.hostPlatform.system;
  lib = pkgs.lib;
in
{
  imports = [ ./programs/zen-browser.nix ];
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
      ;
  };
}
// lib.optionalAttrs isLinux {
  wayland = import ./wayland.nix;
  services = import ./services;
}
