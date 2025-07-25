{
  pkgs,
  username,
  homeDirectory,
  self,
  ...
}:
{
  username = username;
  homeDirectory = homeDirectory;
  stateVersion = "24.11";
  file = import ./file.nix { inherit self; };
  packages = import ./packages.nix { inherit pkgs; };
  shell = import ./shell.nix;
}
