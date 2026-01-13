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
  packages = import ./packages { inherit pkgs; };
  shell = import ./shell.nix;
  # Set EDITOR for nixCats (programs.neovim.defaultEditor is not available)
  # See: https://github.com/BirdeeHub/nixCats-nvim/issues/297
  sessionVariables = {
    EDITOR = "nvim";
  };
}
