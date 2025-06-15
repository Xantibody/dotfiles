{
  inputs,
  ...
}:
let
  inherit (inputs)
    nixpkgs
    xremap
    hyprpanel
    alacritty-theme
    ;
  inherit (inputs) sops-nix home-manager;

  username = "raizawa";
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      hyprpanel.overlay
      alacritty-theme.overlays.default
      (final: prev:{explex = prev.callPackage ../../overlays/explex.nix{};})
      (final: prev:{explex-nf = prev.callPackage ../../overlays/explex-nf.nix{};})
      #   (import ../../overlays/markmap)
    ];
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
        sharedModules = [ sops-nix.homeManagerModules.sops ];
        users."${username}" = import ../../home-manager/home.nix;
        extraSpecialArgs = {
          inherit system;
          inherit pkgs hyprpanel;
        };
      };
    }
  ];
}
