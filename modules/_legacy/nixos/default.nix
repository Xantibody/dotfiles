{ pkgs, inputs, ... }:
{
  imports = [
    {
      programs = import ./programs;
      boot = import ./boot { inherit pkgs; };
      i18n = import ./i18n.nix { inherit pkgs; };
      services = import ./services { inherit pkgs; };
      networking = import ./networking.nix;
      time.timeZone = "Asia/Tokyo";
      hardware = import ./hardware;
      security = import ./security.nix;
      environment = import ./environment.nix { inherit pkgs; };
      virtualisation.docker.enable = true;
    }
    inputs.xremap.nixosModules.default
  ];
}
