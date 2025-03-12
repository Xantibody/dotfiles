{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
    xremap.url = "github:xremap/nix-flake"; 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";

  };

  outputs = inputs@{
    nixpkgs, 
    home-manager,
    hyprpanel,
    ...
  }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      nixos = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
         inherit inputs;
         inherit system;
        };
      };
    };
    homeConfigurations = {
      raizawa = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true; # プロプライエタリなパッケージを許可
            overlays = [
              inputs.hyprpanel.overlay
            ];
         };
         extraSpecialArgs = {
           inherit system;
           inherit inputs;
         };
         modules = [
           ./home.nix
         ];
       };
    };
  };

}
