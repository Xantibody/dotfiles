{
  pkgs,
  lib,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  packages = import ./home/packages { inherit pkgs; };
in
{
  imports = [
    ./programs/zen-browser.nix
  ];
  home = import ./home { inherit packages; };
  programs = import ./programs { inherit pkgs lib isLinux; };
}
