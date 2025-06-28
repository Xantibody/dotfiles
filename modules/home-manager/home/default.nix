{
  pkgs,
  username,
  ...
}:
{
  homeDirectory = "/home/${username}";
  stateVersion = "24.11";
  file = import ./file.nix;
  packages = import ./packages.nix { inherit pkgs; };
}
