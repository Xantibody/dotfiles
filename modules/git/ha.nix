# git worktree を <repo>@<branch> としてリポジトリの隣に切る kawarimidoll/ha。
# 本体は bash/zsh の関数なので、fish からは bash に渡して終了時の cwd だけ受け取る。
# Claude Code には同梱の skill を ~/.claude/skills/ha に置き、source する 1 行は
# configs/claude/CLAUDE.md の Git Workflow に書いてある。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.ha ];
  };
in
{
  flake.modules.homeManager.ha =
    { config, pkgs, ... }:
    let
      # Claude Code の Bash ツール (zsh) が source する固定パス。store のパスは更新のたびに変わる
      script = "${config.xdg.dataHome}/ha/ha.sh";
    in
    {
      xdg.dataFile."ha/ha.sh".source = "${inputs.ha}/ha.sh";
      # AIDEV-NOTE: configs/claude/skills にコピーしない。input から引けば flake update で上流に追従する
      home.file.".claude/skills/ha".source = "${inputs.ha}/skills/ha";

      programs.fish.functions.ha = {
        description = "git worktree を <repo>@<branch> に切る (kawarimidoll/ha)";
        body = ''
          # ha は関数の中で cd するが、bash 側の cd は fish に届かない。
          # 終了時の cwd をファイルで受け取り、こちらで cd し直す
          set -l pwdfile (mktemp)
          HA_PWD_FILE=$pwdfile ${pkgs.bash}/bin/bash -c \
              'source "$1"; shift; ha "$@"; s=$?; pwd -P > "$HA_PWD_FILE"; exit $s' \
              ha ${script} $argv
          set -l s $status
          set -l dir (cat $pwdfile)
          rm -f $pwdfile
          test -n "$dir" -a "$dir" != (pwd -P); and cd $dir
          return $s
        '';
      };
    };

  flake.modules.darwin.ha = share;
  flake.modules.nixos.ha = share;
}
