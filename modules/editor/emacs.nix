# emacs。leaf だけ足して、あとは素のまま。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.emacs ];
  };
in
{
  # AIDEV-NOTE: Emacs.app は nix-mac-app-identity で再署名しない。emacsWithPackages が
  # Contents/MacOS に置くラッパーがシェルスクリプトで、stabilizeApp が受け付けない
  flake.modules.homeManager.emacs = {
    programs.emacs = {
      enable = true;
      extraPackages = epkgs: [ epkgs.leaf ];
    };
  };

  flake.modules.darwin.emacs = share;
  flake.modules.nixos.emacs = share;
}
