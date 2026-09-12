{ pkgs, username, ... }:
{
  imports = [
    {
      environment = import ./environment.nix { inherit pkgs; };
      nix = import ./nix.nix;
      programs = import ./programs.nix;
      security = import ./security.nix;
      fonts = import ./fonts.nix { inherit pkgs; };
      services = import ./services.nix;
      launchd = import ./launchd.nix { inherit pkgs username; };
      ids.gids.nixbld = 350;
    }
    ./system.nix
  ];
}
