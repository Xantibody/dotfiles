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
    ]
    ++ (import ../../overlays);
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
