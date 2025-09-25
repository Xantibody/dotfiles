{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    alacritty-theme
    home-manager
    nix-darwin
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
    {
      # User configuration
      users.users."${username}" = {
        name = username;
        home = homeDirectory;
      };

      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = "nix-command flakes";
          max-jobs = 8;
        };
      };

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
        };
        casks = [
          "alacritty"
          "clipy"
          "macskk"
        ];
      };
      system = {
        stateVersion = 4;
        primaryUser = username;
      };
      ids.gids.nixbld = 350;
    }
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useUserPackages = true;
        users."${username}" = {
          imports = [
            (import ../../modules/home-manager {
              inherit
                pkgs
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
