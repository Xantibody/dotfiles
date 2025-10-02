{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    xremap
    alacritty-theme
    sops-nix
    edgepkgs
    home-manager
    self
    ;

  username = "raizawa";
  system = "x86_64-linux";
  homeDirectory = "/home/${username}";

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      alacritty-theme.overlays.default
      edgepkgs.overlays.default
      (final: prev: {
        iccheck = prev.callPackage ../../overlays/iccheck.nix { };
      })
    ];
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
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [ sops-nix.homeManagerModules.sops ];
        users."${username}" = import ../../modules/home-manager {
          inherit
            pkgs
            homeDirectory
            username
            self
            ;
        };
      };
    }
  ];
}
