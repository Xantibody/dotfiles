{ pkgs, ... }:
let
  darwin = import ./darwin.nix { inherit pkgs; };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
pkgs.lib.optionals isDarwin darwin
