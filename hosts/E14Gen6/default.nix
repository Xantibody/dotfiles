{ inputs }:
let
  inherit (inputs) nixpkgs xremap hyprpanel;
  inherit (inputs) sops-nix home-manager;

  username = "raizawa";
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    overlays = [ hyprpanel.overlay ];
    config.allowUnfree = true;
  };

in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit username xremap nixpkgs;
  };

  modules = [
    ../../nixos
    ./hardware-configuration.nix 
    sops-nix.nixosModules.sops 
    home-manager.nixosModules.home-manager 
    {
      home-manager = {
        useUserPackages = true;
        backupFileExtension = "backup";
      # sharedModules = [ sops-nix.homeManagerModules.sops ];
        users."${username}" = import ../../home-manager/home.nix;
        extraSpecialArgs = {
        inherit system;
        inherit pkgs hyprpanel;
        };
       };
     }
   ];
}
