# コミット前に検証したかを Verified-by trailer で残す commit gate (`rat verify-gate`, tools/verifygate)。
# hook は全リポジトリ共通の git 設定に載るが、動くのは `git config verify.gate` を立てたリポジトリだけ。
# 今は dotfiles だけを observe にし、止めずに記録して誤検知を見る。
# 一時リポジトリでコミットを切って trailer を確かめるテストは checks.rat の go test にある。分岐を足したら場面も足す。
# rat 本体は feature rat が載せる。host は verify-gate と rat を両方並べる。
#
# AIDEV-NOTE: Claude Code の PreToolUse hook にはしない。`rtk hook claude` が同じ Bash に updatedInput を返すので重なり方が定まらず、人の手のコミットにも効かない
# AIDEV-NOTE: core.hooksPath ではなく設定の hook.<name> で足す。hooksPath は各リポジトリの .git/hooks を覆い隠すが、設定の hook はそれと並んで走る
{ config, ... }:
let
  hm = config.flake.modules.homeManager;

  # gate を observe で動かすリポジトリ。gitdir: の末尾の / は配下すべて (ha の worktree を含む) に当たる
  observed = [ "~/Repository/private/github.com/Xantibody/dotfiles/" ];
in
{
  flake.modules.homeManager.verify-gate =
    { config, lib, ... }:
    {
      # AIDEV-NOTE: hook は PATH の rat ではなく my.rat.package のストアパスで呼ぶ。PATH の違う GUI や IDE からのコミットでも見つかるように
      programs.git.settings.hook.verify-gate = {
        event = "commit-msg";
        command = "${lib.getExe config.my.rat.package} verify-gate commit-msg";
      };

      programs.git.includes = map (dir: {
        condition = "gitdir:${dir}";
        contents.verify.gate = "observe";
      }) observed;
    };

  flake.modules.darwin.verify-gate = {
    home-manager.sharedModules = [ hm.verify-gate ];
  };

  flake.modules.nixos.verify-gate = {
    home-manager.sharedModules = [ hm.verify-gate ];
  };
}
