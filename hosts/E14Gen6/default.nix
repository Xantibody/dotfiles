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
  system = "x86_64-linux";
  homeDirectory = "/home/${username}";
in
nixpkgs.lib.nixosSystem {
  inherit system;
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
      nixpkgs.overlays =
        commonOverlays ++ [ inputs.firefox-addons.overlays.default ] ++ (import ../../overlays);
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
