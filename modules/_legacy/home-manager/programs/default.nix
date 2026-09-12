{
  pkgs,
  lib,
  isLinux,
}:
{
  direnv = import ./direnv.nix;
  emacs = import ./emacs.nix;
  fastfetch = import ./fastfetch.nix;
  fzf = import ./fzf.nix;
  kitty = import ./kitty.nix { inherit pkgs; };
  starship = import ./starship.nix;
  zoxide = import ./zoxide.nix;
}
// lib.optionalAttrs isLinux {
  rofi = import ./rofi.nix;
  waybar = import ./waybar.nix;

}
