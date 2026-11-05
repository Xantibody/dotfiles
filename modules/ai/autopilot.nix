# autopilot: Claude Code を無人で走らせ、.ai/plans/ の計画を実装し切るハーネス。
# ISUCON2026 優勝者の human-out-of-the-loop 構成 (起動スクリプト + system prompt 追記 +
# 時刻で監査役を呼ぶ hook + 監査役 subagent) を、競技ではなく機能実装に写したもの。
# 実体は configs/agents/autopilot/ にあり、ここは PATH に載せる 3 コマンドに焼くだけ。
#   autopilot              起動と再開ループ (autopilot.sh)
#   autopilot-stop-hook    Stop hook。計画が終わるまで止めず、監査時刻に監査役を呼ばせる
#   autopilot-compact-hook SessionStart(compact) hook。compaction 後に条件と残項目を戻す
# settings.json / agents.json / system-prompt.md は通常セッションには混ぜず、
# 起動スクリプトが --settings / --agents / --append-system-prompt-file で渡す。
# skill (configs/agents/skills/autopilot) は claude.nix が他の skill と同じ経路で配る。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share.home-manager.sharedModules = [ hm.autopilot ];
in
{
  flake.modules.homeManager.autopilot =
    { pkgs, ... }:
    let
      src = ../../configs/agents/autopilot;
      # 起動スクリプトが参照する 3 ファイルだけを store に置く。test-*.sh は入れない
      shareDir = pkgs.runCommand "autopilot-share" { } ''
        mkdir -p $out
        cp ${src}/settings.json ${src}/agents.json ${src}/system-prompt.md $out/
      '';
      hook =
        name: file:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.jq
            pkgs.gnugrep
            pkgs.gnused
          ];
          text = builtins.readFile file;
        };
    in
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "autopilot";
          runtimeInputs = [
            pkgs.jq
            pkgs.gnugrep
            pkgs.coreutils
            pkgs.gnused
            pkgs.git
          ];
          runtimeEnv.AUTOPILOT_SHARE = shareDir;
          text = builtins.readFile (src + "/autopilot.sh");
        })
        (hook "autopilot-stop-hook" (src + "/stop-hook.sh"))
        (hook "autopilot-compact-hook" (src + "/compact-hook.sh"))
      ];
    };

  flake.modules.darwin.autopilot = share;
  flake.modules.nixos.autopilot = share;
}
