{ inputs, ... }:
let
  inherit (inputs) nixpkgs xremap alacritty-theme sops-nix home-manager;

  username = "raizawa";
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      # (_: _: {waybar_git =inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar;})
      alacritty-theme.overlays.default
      (final: prev: {
        explex = prev.callPackage ../../overlays/explex.nix { };
      })
      (final: prev: {
        explex-nf = prev.callPackage ../../overlays/explex-nf.nix { };
      })
      (final: prev: {
        iccheck = prev.callPackage ../../overlays/iccheck.nix { };
      })
      #(final: prev: { markmap-cli = prev.callPackage ../../overlays/markmap.nix { }; })
      #   (import ../../overlays/markmap)
    ];
    config.allowUnfree = true;
  };

in nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit username xremap nixpkgs; };

  modules = [
    ../../nixos
    ./hardware-configuration.nix
    sops-nix.nixosModules.sops
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [ sops-nix.homeManagerModules.sops ];
        users."${username}" = import ../../home-manager/home.nix;
        extraSpecialArgs = { inherit system pkgs; };
      };
    }
  ];
}
