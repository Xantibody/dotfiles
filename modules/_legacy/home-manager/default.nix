{
  pkgs,
  lib,
  ...
}:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  # home.packages と、fish の `tools` が引く一覧の両方がこのリストを見るので、
  # home/default.nix の中ではなくここで評価して双方に渡す
  packages = import ./home/packages { inherit pkgs; };
in
{
  imports = [
    ./programs/mdsf
    ./programs/zen-browser.nix
  ];
  home = import ./home { inherit packages; };
  programs = import ./programs {
    inherit
      pkgs
      lib
      isLinux
      packages
      ;
  };
}
