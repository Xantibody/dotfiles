{
  pkgs,
  ...
}:
{
  programs = import ./programs;
  boot = import ./boot { inherit pkgs; };
  i18n = import ./i18n { inherit pkgs; };
  services = import ./services { inherit pkgs; };
  nix = import ./nix;
  users = import ./users { inherit pkgs; };
  networking = import ./networking;
  time.timeZone = "Asia/Tokyo";
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [
    hackgen-nf-font
    plemoljp-nf
  ];
  environment = import ./environment { inherit pkgs; };

  virtualisation.docker.enable = true;
}
