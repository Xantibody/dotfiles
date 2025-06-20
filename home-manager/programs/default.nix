{ pkgs }:
{
  git = import ./git.nix;
  neovim = import ./neovim.nix { inherit pkgs; };
  waybar = import ./waybar.nix;
  alacritty = import ./alacritty.nix { inherit pkgs; };
  direnv = import ./direnv.nix;
  starship = import ./starship.nix;
}
