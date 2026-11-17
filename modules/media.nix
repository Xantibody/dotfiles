# Pull a video's subtitles with yt-dlp and translate them locally with PLaMo.
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.media =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        plamo-translate
        yt-dlp
      ];
    };

  flake.modules.darwin.media = {
    nixpkgs.overlays = [ (import ../overlays/plamo-translate.nix) ];
    home-manager.sharedModules = [ hm.media ];
  };
}
