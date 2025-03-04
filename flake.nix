{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
    xremap.url = "github:xremap/nix-flake"; 
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
  };

  outputs = inputs@{
    nixpkgs, 
    home-manager,
    alacritty-theme,
    ...
  }: {
    nixosConfigurations = {
      nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        specialArgs = {
         inherit inputs; # `inputs = inputs;`と等しい
        };
      };
    };
     homeConfigurations = {
       raizawa = inputs.home-manager.lib.homeManagerConfiguration {
         pkgs = import inputs.nixpkgs {
           system = "x86_64-linux";
           config.allowUnfree = true; # プロプライエタリなパッケージを許可
         };
         extraSpecialArgs = {
           inherit inputs;
         };
         modules = [
           ./home.nix
         ];
       };
    };
  };

}
