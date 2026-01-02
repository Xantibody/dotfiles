{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    xremap
    sops-nix
    home-manager
    self
    firefox-addons
    zen-browser
    ;

  commonOverlays = import ../overlays.nix { inherit inputs; };
  commonHomeModules = import ../home-modules.nix { inherit inputs; };

  username = "raizawa";
  system = "x86_64-linux";
  homeDirectory = "/home/${username}";
  pkgs = import nixpkgs {
    inherit system;
    overlays =
      commonOverlays
      ++ [
        firefox-addons.overlays.default
      ]
      ++ (import ../../overlays);
    config.allowUnfree = true;
  };

in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit username xremap nixpkgs; };

  modules = [
    ../../modules/nixos
    ../../modules/nixos/hardware-configuration.nix
    sops-nix.nixosModules.sops
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        extraSpecialArgs = { inherit inputs; };
        sharedModules = commonHomeModules ++ [
          sops-nix.homeManagerModules.sops
        ];
        users."${username}" = import ../../modules/home-manager {
          inherit
            pkgs
            inputs
            homeDirectory
            username
            self
            ;
        };
      };
    }
  ];
}
