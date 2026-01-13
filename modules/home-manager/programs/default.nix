{
  pkgs,
  lib,
  isLinux,
}:
{
  alacritty = import ./alacritty.nix { inherit pkgs; };
  direnv = import ./direnv.nix;
  fastfetch = import ./fastfetch.nix;
  fish = import ./fish.nix { inherit pkgs; };
  git = import ./git.nix;
  # neovim is provided by nixCats, use home.sessionVariables for EDITOR
  zellij = import ./zellij.nix;
  starship = import ./starship.nix;
  zoxide = import ./zoxide.nix;
  kitty = import ./kitty.nix { inherit pkgs; };
  emacs = import ./emacs.nix;
  firefox = import ./firefox.nix;
}
// lib.optionalAttrs isLinux {
  rofi = import ./rofi.nix;
  waybar = import ./waybar.nix;

}
