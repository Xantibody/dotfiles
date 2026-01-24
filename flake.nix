{
  description = "r-aizawa nix conf now!";
  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-25.05";
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
    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-nur.url = "github:Xantibody/nur-packages";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.cl-nix-lite.url = "github:r4v3n6101/cl-nix-lite/url-fix";
    };
    systems.url = "github:nix-systems/default";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    llm-agents.url = "github:Xantibody/llm-agents.nix/feature/overlay-support";
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
          work-macbook-pro-m4-attm = import ./hosts/work-macbook-pro-m4-attm { inherit inputs; };
          private-macbook-pro-m3 = import ./hosts/private-macbook-pro-m3 { inherit inputs; };
        };
      };
      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                vim-startuptime
              ]
              # NixOSの指紋キャッシュを消すための依存関係
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                python312
                libfprint
                gobject-introspection
                gtk3
                python3Packages.pygobject3
                gusb
                json-glib
              ];
          };
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              nixfmt.enable = true;
              fish_indent.enable = true;
              stylua.enable = true;
              shfmt.enable = true;
              oxfmt.enable = true;
            };
          };
        };
    };
}
