{
  description = "r-aizawa nix conf now!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; 
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    hyprpanel.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = 
  {
    flake-parts,
    treefmt-nix,
    ...
  # }@inputs:
    # nixpkgs, 
    # home-manager,
    # hyprpanel,
    # ...
  }@inputs: 

  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = [
    "x86_64-linux"
    ];

    imports = [
      treefmt-nix.flakeModule
      inputs.flake-parts.flakeModules.easyOverlay
    ];
  
    flake = {
      nixosConfigurations = {
        E14Gen6 = import ./hosts/E14Gen6 {
        inherit inputs;
        };  
      };
    };

    perSystem =
      { pkgs, ... }:
      {
       overlayAttrs = {
          inherit (pkgs) hyprpanel;
        };
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            actionlint.enable = true;
            nixfmt.enable = true;
            taplo.enable = true;
            jsonfmt.enable = true;
            yamlfmt.enable = true;
            fish_indent.enable = true;
            stylua.enable = true;
            shfmt.enable = true;
            prettier.enable = true;
          };
        };
      };
  };
}
