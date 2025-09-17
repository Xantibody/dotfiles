{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    alacritty-theme
    sops-nix
    home-manager
    self
    ;

  username = "usr0200777";
  system = "aarch64-darwin";
  homeDirectory = "/Users/${username}";

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      alacritty-theme.overlays.default
      (final: prev: {
        iccheck = prev.callPackage ../../overlays/iccheck.nix { };
      })
    ];
    config.allowUnfree = true;
  };

in
home-manager.lib.homeManagerConfiguration {
  pkgs = pkgs;
  modules = [
    ../../modules/home-manager
  ];
  extraSpecialArgs = {
    inherit
      pkgs
      username
      homeDirectory
      self
      ;
  };
}
