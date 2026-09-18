# Claude が書く PR / issue 本文を textlint にかける。
# ルールの選定と自前ルールは configs/claude/textlint/ にあり、`lint-body <file>` がそれを読む。
# skill が本文を書いた後に lint-body を回し、`gh pr create` などの --body-file は
# lint-body-hook (pull-request / issue skill の frontmatter が登録する PreToolUse hook) が
# もう一度かけて、指摘が残っていればコマンドを止める。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  overlay = import ../../overlays/textlint-rules.nix;
  share = {
    nixpkgs.overlays = [ overlay ];
    home-manager.sharedModules = [ hm.textlint ];
  };

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
      ];
      text = ''
        exec textlint \
          --config ${../../configs/claude/textlint/textlintrc.json} \
          --rulesdir ${../../configs/claude/textlint/rules} \
          "$@"
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

  flake.modules.darwin.textlint = share;
  flake.modules.nixos.textlint = share;

  # 自前ルールと設定の読み込みを fixture で検査する。
  # textlint は解決できないルールが 1 つでもあると設定全体を黙って捨てて exit 0 になるので、
  # ok.md が通るだけでは足りず、ng.md で各ルールが実際に鳴ることまで見る。
  perSystem =
    { pkgs, ... }:
    let
      lintBody = mkLintBody (pkgs.extend overlay);
      rules = [
        "no-soft-break"
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
