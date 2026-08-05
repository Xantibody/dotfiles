{ inputs, ... }:
let
  inherit (inputs)
    brew-nix
    home-manager
    nix-darwin
    nixpkgs
    self
    zen-browser
    firefox-addons
    mac-app-util
    ;

  commonOverlays = import ../overlays.nix { inherit inputs; };
  darwinOverlays = import ../darwin-overlays.nix { inherit inputs; };
  commonHomeModules = import ../home-modules.nix { inherit inputs; };

  username = "ryu.aizawa";
  system = "aarch64-darwin";
  homeDirectory = "/Users/${username}";

  # Mac15,3 は 8 コア / 16GB。共有の既定値 (11 コア / 24GB) は物理を超えていて、
  # Virtualization.framework が "memorySize is greater than
  # maximumAllowedMemorySize" で構成ごと拒否する。ホストにも余裕を残す。
  colima = {
    cpu = 6;
    memory = 8;
  };

  pkgs = import nixpkgs {
    inherit system;
    overlays =
      commonOverlays
      ++ darwinOverlays
      ++ [
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
      colima
      ;
  };
  modules = [
    ../../modules/darwin
    home-manager.darwinModules.home-manager
    mac-app-util.darwinModules.default
    inputs.magical-merchant.darwinModules.default
    {
      services.magical-merchant = {
        enable = true;
        workersUrl = "https://magical-merchant.sync.r-aizawa.com";
      };
    }
    {
      environment.systemPackages =
        # 署名保持版 Zen を /Applications/Nix Apps/ へ署名保持コピーさせ、
        # 1Password 連携を成立させる (詳細は zen-beta-signed.nix のコメント)。
        [ (import ../../modules/darwin/zen-beta-signed.nix { inherit inputs pkgs; }) ];
    }
    {
      home-manager = {
        useGlobalPkgs = true;
        extraSpecialArgs = { inherit inputs; };
        users."${username}" = {
          imports = commonHomeModules ++ [
            mac-app-util.homeManagerModules.default
            (import ../../modules/home-manager {
              inherit
                pkgs
                inputs
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
