{ pkgs, xremap, ... }:
let
  configuration = {
    programs = import ./programs;
    boot = import ./boot { inherit pkgs; };
    i18n = import ./i18n { inherit pkgs; };
    services = import ./services { inherit pkgs; };
    nix = import ./nix;
    users = import ./users { inherit pkgs; };
    networking = import ./networking;
    time.timeZone = "Asia/Tokyo";
    hardware = import ./hardware.nix;
    security = import ./security;
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
in { imports = [ configuration xremap.nixosModules.default ]; }
