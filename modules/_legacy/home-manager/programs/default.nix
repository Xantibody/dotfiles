{ lib, isLinux, ... }:
lib.optionalAttrs isLinux {
  rofi = import ./rofi.nix;
  waybar = import ./waybar.nix;
}
