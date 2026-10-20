# Claude が書く PR / issue 本文を textlint と osekkai lint にかける。
# ルールの選定と自前ルールは configs/agents/textlint/ にあり、`lint-body <file>` がそれを読む。
# osekkai のルールは osekkai 本体 (flake input) が持つ。
# skill が本文を書いた後に lint-body を回し、`gh pr create` などの --body-file は
# lint-body-hook (pull-request / issue skill の frontmatter が登録する PreToolUse hook) が
# もう一度かけて、指摘が残っていればコマンドを止める。
#
# claude feature の一部なので `_` 始まりにして import-tree から外し、claude.nix が imports で読む。
# host が列挙するのは claude だけで、darwin / nixos への配線も claude.nix 側にある。
{ inputs, lib, ... }:
let
  overlay = lib.composeExtensions inputs.osekkai.overlays.default (
    import ../../overlays/textlint-rules.nix
  );

  # AIDEV-NOTE: 設定と rulesdir は store パスで焼き込む。~/.claude に置くと cwd の .textlintrc に負ける
  mkLintBody =
    pkgs:
    pkgs.writeShellApplication {
      name = "lint-body";
      runtimeInputs = [
        (pkgs.textlint.withPackages (
          with pkgs;
          [
            textlint-rule-preset-ja-technical-writing
            textlint-rule-preset-ja-spacing
            textlint-rule-preset-ai-writing
            textlint-rule-ja-hiraku
            textlint-rule-period-in-list-item
            textlint-rule-no-start-duplicated-conjunction
            textlint-rule-max-comma
          ]
        ))
        pkgs.osekkai
      ];
      # 日本語の文は textlint、箇条と節の構造は osekkai が見る。fix できるのは textlint だけなので
      # 先に回し、直った後のファイルを osekkai にかける。どちらかが鳴れば exit 1。
      # osekkai lint はファイルと --format しか取らないので、textlint 向けの他のオプションは落とす。
      text = ''
        files=()
        osekkai_args=()
        args=("$@")
        while (($#)); do
          case $1 in
            --format | -f)
              [[ ''${2:-} == json ]] && osekkai_args+=(--format json)
              shift 2 || shift
              ;;
            --format=json) osekkai_args+=(--format json) && shift ;;
            -*) shift ;;
            *) files+=("$1") && shift ;;
          esac
        done

        status=0
        textlint \
          --config ${../../configs/agents/textlint/textlintrc.json} \
          --rulesdir ${../../configs/agents/textlint/rules} \
          "''${args[@]}" || status=1
        if ((''${#files[@]})); then
          osekkai lint "''${osekkai_args[@]}" "''${files[@]}" || status=1
        fi
        exit "$status"
      '';
    };
in
{
  flake.modules.homeManager.textlint =
    { pkgs, ... }:
    let
      lintBody = mkLintBody pkgs;
      hook = pkgs.writeShellApplication {
        name = "lint-body-hook";
        runtimeInputs = [
          pkgs.jq
          lintBody
        ];
        text = builtins.readFile ./textlint-hook.sh;
      };
    in
    {
      # hook は settings.json ではなく pull-request / issue skill の frontmatter が登録する。
      # skill が呼ばれたセッションだけ効き、無関係な Bash 呼び出しに hook が付いて回らない。
      home.packages = [
        lintBody
        hook
      ];
    };

  # 自前ルールと設定の読み込みを fixture で検査する。
  # textlint は解決できないルールが 1 つでもあると設定全体を黙って捨てて exit 0 になるので、
  # ok.md が通るだけでは足りず、ng.md で各ルールが実際に鳴ることまで見る。
  perSystem =
    { pkgs, ... }:
    let
      lintBody = mkLintBody (pkgs.extend overlay);
      # textlint も osekkai も JSON の ruleId で名前を出すので、両方の規則をここに並べる
      rules = [
        "no-soft-break"
        # osekkai のルール。dotfiles 側の同名ルールは消したので、これが鳴れば osekkai まで回っている
        "no-list-item-separator"
        "no-empty-section"
        "ja-spacing/ja-space-between-half-and-full-width"
        "ja-hiraku"
        "@textlint-ja/ai-writing/no-ai-list-formatting"
        "ja-technical-writing/sentence-length"
      ];
    in
    {
      checks.textlint-body = pkgs.runCommand "textlint-body" { nativeBuildInputs = [ lintBody ]; } ''
        lint-body ${./textlint-fixtures/ok.md}
        lint-body --format json ${./textlint-fixtures/ng.md} > ng.json || true
        for rule in ${builtins.concatStringsSep " " rules}; do
          grep -q "\"ruleId\":\"$rule\"" ng.json || { echo "ng.md did not trigger $rule"; cat ng.json; exit 1; }
        done
        touch $out
      '';
    };
}
