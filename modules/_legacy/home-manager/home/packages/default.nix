{ pkgs, ... }:
let
  darwin = import ./darwin.nix { inherit pkgs; };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
with pkgs;
(
  [
    yaskkserv2
  ]
  ++ pkgs.lib.optionals isDarwin darwin
)
