{ pkgs, xremap, ... }:
let
  configuration = {
    programs = import ./programs.nix;
    boot = import ./boot.nix { inherit pkgs; };
    i18n = import ./i18n.nix { inherit pkgs; };
    services = import ./services.nix { inherit pkgs; };
    nix = import ./nix.nix;
    users = import ./users.nix { inherit pkgs; };
    networking = import ./networking.nix;
    time.timeZone = "Asia/Tokyo";
    hardware = import ./hardware.nix;
    security = import ./security.nix;
    nixpkgs.config.allowUnfree = true;
    fonts.packages = with pkgs; [
      hackgen-nf-font
      plemoljp-nf
      nerd-fonts.jetbrains-mono
      explex
      explex-nf
    ];
    environment = import ./environment.nix { inherit pkgs; };
    virtualisation.docker.enable = true;
  };
in
{
  imports = [
    configuration
    xremap.nixosModules.default
  ];
}
