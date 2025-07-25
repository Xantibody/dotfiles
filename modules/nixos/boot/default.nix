{ pkgs, ... }:
{
  loader = import ./loader.nix;
  kernelPackages = pkgs.linuxPackages_latest;
}
