{ inputs }:
let
  inherit (inputs) nixpkgs xremap hyprpanel;
  inherit (inputs) sops-nix home-manager;

  username = "raizawa";
  system = "x86_64-linux";
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
      home-manager.useUserPackages = true;
      home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
      home-manager.users."${username}" = import ../../home-manager/home.nix;
      home-manager.extraSpecialArgs = {
        inherit system;
        inherit (inputs) nixpkgs hyprpanel;
      };
     }
  ];
}
