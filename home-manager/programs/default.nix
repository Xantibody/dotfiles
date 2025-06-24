{ pkgs }:
{
  alacritty = import ./alacritty.nix { inherit pkgs; };
  direnv = import ./direnv.nix;
  git = import ./git.nix;
  neovim = import ./neovim.nix { inherit pkgs; };
  rofi = import ./rofi.nix;
  starship = import ./starship.nix;
  waybar = import ./waybar.nix;
}
