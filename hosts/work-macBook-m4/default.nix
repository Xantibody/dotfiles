{ inputs, ... }:
let
  inherit (inputs)
    alacritty-theme
    edgepkgs
    home-manager
    nix-darwin
    nixpkgs
    self
    ;

  username = "ryu.aizawa";
  system = "aarch64-darwin";
  homeDirectory = "/Users/${username}";

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

      fonts.packages = [ pkgs.explex-nf ];
      system = {
        stateVersion = 4;
        primaryUser = username;
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToControl = true;
        };
        defaults = {
          NSGlobalDomain = {
            KeyRepeat = 10;
            InitialKeyRepeat = 1;
          };
        };
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
