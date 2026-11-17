# Pull a video's subtitles with yt-dlp and translate them locally with PLaMo.
# The subtitles command joins the two, and its skill tells agents to use it;
# both live in configs/media/skills/subtitles and reach only the hosts that
# list this feature, so an agent that sees the skill has the tools too.
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.media =
    { pkgs, ... }:
    let
      skill = ../configs/media/skills/subtitles;
      subtitles = pkgs.buildGoModule {
        pname = "subtitles";
        version = "0.1.0";
        src = skill + "/scripts/subtitles";
        vendorHash = null;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postInstall = ''
          wrapProgram $out/bin/subtitles --prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.plamo-translate
              pkgs.yt-dlp
            ]
          }
        '';
        meta.mainProgram = "subtitles";
      };
    in
    {
      home.packages = with pkgs; [
        plamo-translate
        subtitles
        yt-dlp
      ];
      # AIDEV-NOTE: kept out of configs/agents/skills, which every host gets
      my.skills.subtitles = skill;
    };

  flake.modules.darwin.media = {
    nixpkgs.overlays = [ (import ../overlays/plamo-translate.nix) ];
    home-manager.sharedModules = [ hm.media ];
  };
}
