# vercel-labs/agent-browser。AI エージェントが画面を見るための headless Chrome の CLI。
# Claude は implement で描画を確かめるとき、pull-request で before / after を撮るときに使い、
# 手順は configs/claude/skills/browser-verify にある。上流の使い方 skill は本体が同梱している。
# Chrome 本体は store に無く、初回に `agent-browser install` が Chrome for Testing を落とす。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.agent-browser ];
  };
in
{
  flake.modules.homeManager.agent-browser =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.agent-browser ];
      # AIDEV-NOTE: ha と同じく configs/claude/skills にコピーしない。package の版と skill の版が常に揃う
      home.file.".claude/skills/agent-browser".source = "${pkgs.agent-browser}/skills/agent-browser";
    };

  flake.modules.darwin.agent-browser = share;
  flake.modules.nixos.agent-browser = share;
}
