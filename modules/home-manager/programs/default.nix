{
  pkgs,
  lib,
  isLinux,
}:
{
  direnv = import ./direnv.nix;
  emacs = import ./emacs.nix;
  fastfetch = import ./fastfetch.nix;
  fish = import ./fish.nix { inherit pkgs; };
  git = import ./git.nix;
  kitty = import ./kitty.nix { inherit pkgs; };
  starship = import ./starship.nix;
  zellij = import ./zellij.nix;
  zoxide = import ./zoxide.nix;
}
// lib.optionalAttrs isLinux {
  rofi = import ./rofi.nix;
  waybar = import ./waybar.nix;

}
