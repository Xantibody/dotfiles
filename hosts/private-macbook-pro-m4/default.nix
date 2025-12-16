{ inputs, ... }:
let
  inherit (inputs)
    alacritty-theme
    brew-nix
    edgepkgs
    mcp-servers-nix
    home-manager
    nix-darwin
    nixpkgs
    nixvim
    self
    zen-browser
    firefox-addons
    mac-app-util
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
      brew-nix.overlays.default
      firefox-addons.overlays.default
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
      zen-browser
      ;
  };
  modules = [
    ../../modules/darwin
    home-manager.darwinModules.home-manager
    mac-app-util.darwinModules.default
    {
      home-manager = {
        useGlobalPkgs = true;
        users."${username}" = {
          imports = [
            nixvim.homeModules.nixvim
            zen-browser.homeModules.beta
            mac-app-util.homeManagerModules.default
            (import ../../modules/home-manager {
              inherit
                pkgs
                mcp-servers-nix
                homeDirectory
                username
                zen-browser
                self
                ;
            })
          ];
        };
      };
    }
  ];
}
