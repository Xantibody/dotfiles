{ inputs, ... }:
let
  inherit (inputs)
    brew-nix
    home-manager
    nix-darwin
    nixpkgs
    self
    zen-browser
    firefox-addons
    mac-app-util
    ;

  commonOverlays = import ../overlays.nix { inherit inputs; };
  commonHomeModules = import ../home-modules.nix { inherit inputs; };

  username = "ryu.aizawa";
  system = "aarch64-darwin";
  homeDirectory = "/Users/${username}";

  pkgs = import nixpkgs {
    inherit system;
    overlays =
      commonOverlays
      ++ [
        brew-nix.overlays.default
        firefox-addons.overlays.default
      ]
      ++ (import ../../overlays)
      ++ [ (import ../../overlays/gtk3-no-doc.nix) ];
    config.allowUnfree = true;
  };

in
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit
      inputs
      pkgs
      username
      homeDirectory
      zen-browser
      ;
  };
  modules = [
    ../../modules/darwin
    home-manager.darwinModules.home-manager
    mac-app-util.darwinModules.default
    {
      home-manager = {
        useGlobalPkgs = true;
        extraSpecialArgs = { inherit inputs; };
        users."${username}" = {
          imports = commonHomeModules ++ [
            mac-app-util.homeManagerModules.default
            (import ../../modules/home-manager {
              inherit
                pkgs
                inputs
                homeDirectory
                username
                self
                ;
            })
          ];
        };
      };
    }
  ];
}
