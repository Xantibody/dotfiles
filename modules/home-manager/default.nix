{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  system = pkgs.stdenv.hostPlatform.system;
  lib = pkgs.lib;
  # home.packages と、fish の `tools` が引く一覧の両方がこのリストを見るので、
  # home/default.nix の中ではなくここで評価して双方に渡す
  packages = import ./home/packages { inherit pkgs; };
in
{
  imports = [
    ./programs/mdsf
    ./programs/zen-browser.nix
  ];
  home = import ./home {
    inherit
      pkgs
      lib
      homeDirectory
      username
      isLinux
      self
      packages
      ;
  };
  programs = import ./programs {
    inherit
      pkgs
      lib
      isLinux
      packages
      ;
  };
}
// lib.optionalAttrs isLinux {
  wayland = import ./wayland.nix;
  services = import ./services;
}
