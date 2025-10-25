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
  kittyFontSize = 11;

  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      alacritty-theme.overlays.default
      edgepkgs.overlays.default
      mcp-servers-nix.overlays.default
    ]
    ++ (import ../../overlays)
    ++ [ (import ../../overlays/gtk3-no-doc.nix) ];
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
      kittyFontSize
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
                kittyFontSize
                ;
            })
          ];
        };
      };
    }
  ];
}
