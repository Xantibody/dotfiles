{ packages, ... }:
{
  file = import ./file.nix;
  inherit packages;
  # Set EDITOR for nixCats (programs.neovim.defaultEditor is not available)
  # See: https://github.com/BirdeeHub/nixCats-nvim/issues/297
  sessionVariables = {
    EDITOR = "nvim";
  };
  sessionPath = [ "$HOME/.local/bin" ];
}
