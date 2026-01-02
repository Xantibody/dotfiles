{ inputs, ... }:
let
  inherit (inputs)
    home-manager
    nix-darwin
    nixpkgs
    self
    ;

  commonOverlays = import ../overlays.nix { inherit inputs; };
  commonHomeModules = import ../home-modules.nix { inherit inputs; };

  username = "ryu.aizawa";
  system = "aarch64-darwin";
  homeDirectory = "/Users/${username}";

  pkgs = import nixpkgs {
    inherit system;
    overlays = commonOverlays ++ (import ../../overlays) ++ [ (import ../../overlays/gtk3-no-doc.nix) ];
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
      ;
  };
  modules = [
    ../../modules/darwin
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        extraSpecialArgs = { inherit inputs; };
        users."${username}" = {
          imports = commonHomeModules ++ [
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
