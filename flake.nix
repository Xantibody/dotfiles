{
  inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
  xremap.url = "github:xremap/nix-flake"; 
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{nixpkgs, home-manager, ...}: {
    nixosConfigurations = {
      nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
            {
             home-manager.useGlobalPkgs = true;
             home-manager.useUserPackages = true;
             home-manager.users.jdoe = import ./home.nix;

             # Optionally, use home-manager.extraSpecialArgs to pass
             # arguments to home.nix
           }
        ];
        specialArgs = {
         inherit inputs; # `inputs = inputs;`と等しい
        };
      };
    };
  };
}
