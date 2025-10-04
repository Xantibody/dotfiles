{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home = import ./home {
    inherit
      pkgs
      homeDirectory
      username
      isLinux
      self
      ;
  };
  programs = import ./programs { inherit pkgs isLinux; };
  wayland = import ./wayland.nix { inherit isLinux; };
  services = import ./services { inherit isLinux; };
}
