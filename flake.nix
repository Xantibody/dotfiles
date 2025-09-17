{
  description = "r-aizawa nix conf now!";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    alacritty-theme = {
      url = "github:alexghr/alacritty-theme.nix";
    };
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
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      flake-parts,
      treefmt-nix,
      systems,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [ treefmt-nix.flakeModule ];

      flake = {
        nixosConfigurations = {
          E14Gen6 = import ./hosts/E14Gen6 { inherit inputs; };
        };
        darwinConfigurations = {
          work-macBook-m4 = import ./hosts/work-macBook-m4 { inherit inputs; };
        };
      };
      perSystem = {
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
