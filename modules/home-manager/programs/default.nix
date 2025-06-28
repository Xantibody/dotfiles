{ pkgs, isLinux }:
{
  alacritty = import ./alacritty.nix { inherit pkgs; };
  direnv = import ./direnv.nix;
  fastfetch = import ./fastfetch.nix;
  git = import ./git.nix;
  neovim = import ./neovim.nix { inherit pkgs; };
  rofi = import ./rofi.nix { inherit isLinux; };
  starship = import ./starship.nix;
  waybar = import ./waybar.nix { inherit isLinux; };
}
