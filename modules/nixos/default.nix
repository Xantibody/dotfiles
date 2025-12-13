{ pkgs, xremap, ... }:
let
  configuration = {
    programs = import ./programs;
    boot = import ./boot { inherit pkgs; };
    i18n = import ./i18n.nix { inherit pkgs; };
    services = import ./services { inherit pkgs; };
    nix = import ./nix.nix;
    users = import ./users.nix { inherit pkgs; };
    networking = import ./networking.nix;
    time.timeZone = "Asia/Tokyo";
    hardware = import ./hardware;
    security = import ./security.nix;
    nixpkgs.config.allowUnfree = true;
    environment = import ./environment.nix { inherit pkgs; };
    virtualisation.docker.enable = true;
    fonts = import ./fonts.nix { inherit pkgs; };
  };
in
{
  imports = [
    configuration
    xremap.nixosModules.default
  ];
}
