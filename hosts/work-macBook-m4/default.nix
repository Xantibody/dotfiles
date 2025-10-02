{ inputs, ... }:
let
  inherit (inputs)
    alacritty-theme
    edgepkgs
    mcp-servers-nix
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
      mcp-servers-nix.overlays.default
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
        shell = pkgs.fish;
      };
      environment.shells = [ pkgs.fish ];
      environment.systemPackages = [
        pkgs.colima
        pkgs.lima-additional-guestagents
        pkgs.docker
        pkgs.docker-compose
        pkgs.docker-buildx
      ];
      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = "nix-command flakes";
          max-jobs = 8;
        };
      };
      programs.fish.enable = true;
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
      security.pam.services.sudo_local.touchIdAuth = true;
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
            KeyRepeat = 2;
            InitialKeyRepeat = 15;
          };
          dock = {
            show-recents = false;
            persistent-apps = [
              { app = "/System/Applications/Launchpad.app"; }
              { app = "${pkgs.slack}/Applications/slack.app/"; }
              { app = "${pkgs.google-chrome}/Applications/Google Chrome.app"; }
              {
                spacer = {
                  small = true;
                };
              }
              { app = "${pkgs.kitty}/Applications/kitty.app"; }

            ];
          };
        };
      };
      ids.gids.nixbld = 350;
    }
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        users."${username}" = {
          imports = [
            (import ../../modules/home-manager {
              inherit
                pkgs
                mcp-servers-nix
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
