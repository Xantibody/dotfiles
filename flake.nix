{
  description = "r-aizawa nix conf now!";
  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixos-unstable-small";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    # modules/ 配下の .nix を再帰的に flake-parts の module として読む。
    # 先頭が `_` のパスは読まないので、flake-parts module でないものはそこに置く。
    import-tree = {
      url = "github:vic/import-tree";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xremap = {
      url = "github:xremap/nix-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        brew-api.follows = "brew-api";
        nixpkgs.follows = "nixpkgs";
        nix-darwin.follows = "nix-darwin";
      };
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
    my-nur = {
      url = "github:Xantibody/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
        # cl-nix-lite は mac-app-util の trampoline を組むためだけの依存で、
        # 自前の nixpkgs / flake-parts / treefmt-nix をさらに引いてくる
        cl-nix-lite.inputs.nixpkgs.follows = "nixpkgs";
        cl-nix-lite.inputs.flake-parts.follows = "flake-parts";
        cl-nix-lite.inputs.systems.follows = "systems";
        cl-nix-lite.inputs.treefmt-nix.follows = "treefmt-nix";
      };
    };
    systems.url = "github:nix-systems/default";
    # 自分では使わないが、下の input 群が持ち込む 4 コピーを 1 つに畳むために置く
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        systems.follows = "systems";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    arto = {
      url = "github:arto-app/Arto";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ichigyo-ls = {
      url = "github:Xantibody/ichigyo-ls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    kotdiff = {
      url = "github:Xantibody/kotdiff";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    magical-merchant = {
      url = "github:Xantibody/magical-merchant";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # flake.modules.<class>.<name> を生やす flake-parts の extras/modules.nix。
        # lazyAttrsOf なので、host が列挙しない機能は評価されない。
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
    };
}
