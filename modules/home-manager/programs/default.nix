{
  pkgs,
  lib,
  isLinux,
}:
{
  direnv = import ./direnv.nix;
  fastfetch = import ./fastfetch.nix;
  fish = import ./fish.nix { inherit pkgs; };
  git = import ./git.nix;
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
