# git worktree を <repo>@<branch> としてリポジトリの隣に切る kawarimidoll/ha。
# 本体は bash/zsh の関数なので、fish からは bash に渡して終了時の cwd だけ受け取る。
# 同梱の skill は my.skills に載せて各 agent の skill dir に並べてもらう。agent の Bash
# (非対話の zsh / bash) からは PATH 上の wrapper `ha` が関数を source して呼ぶので、
# 指示書に source の手順を書かなくてよい。
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
      # AIDEV-NOTE: configs/agents/skills にコピーしない。input から引けば flake update で上流に追従する
      my.skills.ha = "${inputs.ha}/skills/ha";

      # 関数の中の cd は呼び出し元に届かないので、cwd が変わった時だけ最後にその path を出す。
      # fish では下の関数が同名で先に見つかり、この wrapper は使われない
      home.packages = [
        (pkgs.writeShellScriptBin "ha" ''
          start=$(pwd -P)
          source ${inputs.ha}/ha.sh
          ha "$@"
          s=$?
          end=$(pwd -P)
          [ "$end" != "$start" ] && echo "cwd: $end"
          exit $s
        '')
      ];

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
