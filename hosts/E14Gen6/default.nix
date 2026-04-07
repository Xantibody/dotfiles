{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    xremap
    sops-nix
    home-manager
    self
    ;

  commonOverlays = import ../overlays.nix { inherit inputs; };
  commonHomeModules = import ../home-modules.nix { inherit inputs; };

  username = "raizawa";
  homeDirectory = "/home/${username}";
in
nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit
      username
      xremap
      nixpkgs
      inputs
      ;
  };

  modules = [
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.overlays =
        commonOverlays ++ [ inputs.firefox-addons.overlays.default ] ++ (import ../../overlays);
      system.stateVersion = "24.11";
    }
    ../../modules/nixos
    ../../modules/nixos/hardware-configuration.nix
    sops-nix.nixosModules.sops
    home-manager.nixosModules.home-manager
    (
      { pkgs, ... }:
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
    )
  ];
}
