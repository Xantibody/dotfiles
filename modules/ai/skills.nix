# skill の validator (`rat skill validate`、tools/skill/validate) を CI で回す check。
# 手で回すだけだと、改名で残った参照や隠した skill への hand-off が次に誰かが回すまで見つからない。
# 全 skill に --offline --strict でかけ、configs/agents/README.md の図が skill の dir と揃っているかも見る。
# baseline の Goal の判定ファイル一覧と settings.json の permissions.ask が揃っているかも見る。
# validator 自身の go test は checks.rat (modules/rat.nix) が回す。skill が持つ他の Go スクリプト (terminal-verify の shot、reliability-checklist の checklist) はここで build して test する。
{ inputs, self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    let
      # terminal-verify の tape を組む shot。vhs の罠を固定した go test を checkPhase が回す
      shot = pkgs.buildGoModule {
        pname = "terminal-verify-shot";
        version = "0.1.0";
        src = ../../configs/agents/skills/terminal-verify/scripts/shot;
        vendorHash = null;
        meta.mainProgram = "shot";
      };
      # REVIEW.md を base から読んで diff に当てる checklist。一時 repo を作るテストに git が要る
      checklist = pkgs.buildGoModule {
        pname = "reliability-checklist";
        version = "0.1.0";
        src = ../../configs/agents/skills/reliability-checklist/scripts/checklist;
        vendorHash = null;
        nativeCheckInputs = [ pkgs.git ];
        meta.mainProgram = "checklist";
      };
    in
    {
      # sandbox には ~/.claude/skills が無いので、flake input が配る skill は --known で渡す。
      # AIDEV-NOTE: my.skills は home-manager の option で perSystem からは読めないので、input の skill dir を直接並べる。本文が新しい外の skill を読み込んだらここに足す
      # AIDEV-NOTE: self に .git は入らないので eval の commit hash はここでは見ない (validator が note を出す)。手元で回したときだけ検査される
      checks.skills = pkgs.runCommand "skills" { } ''
        dirs=()
        for f in ${self}/configs/agents/skills/*/SKILL.md ${self}/configs/media/skills/*/SKILL.md; do
          dirs+=("''${f%/SKILL.md}")
        done
        ${pkgs.lib.getExe self'.packages.rat} skill validate --offline --strict \
          --readme ${self}/configs/agents/README.md \
          --known ${inputs.osekkai}/skills/osekkai \
          --known ${inputs.ha}/skills/ha \
          "''${dirs[@]}"
        touch $out
      '';
      # baseline の Goal の判定ファイル一覧と settings.json の permissions.ask の Edit(...) が揃っているかを見る。
      # 片方だけ足すと、確認が出ないのに goal-review は判定ファイルとして扱う (または逆) ずれが黙って起きる
      checks.judge-files = pkgs.runCommand "judge-files" { nativeBuildInputs = [ pkgs.jq ]; } ''
        awk '/^```gitignore$/ { f = 1; next } /^```/ { f = 0 } f' \
          ${self}/configs/agents/skills/baseline/SKILL.md | sort > goal
        jq -r '.permissions.ask[] | select(startswith("Edit(")) | ltrimstr("Edit(") | rtrimstr(")")' \
          ${self}/configs/agents/settings.json | sort > ask
        if [ ! -s goal ]; then
          echo "baseline/SKILL.md has no gitignore block of judge files" >&2
          exit 1
        fi
        if ! diff -u goal ask; then
          echo "baseline's Judge files (-) and settings.json permissions.ask (+) differ: add or remove the pattern in both" >&2
          exit 1
        fi
        touch $out
      '';
      checks.terminal-verify-shot = shot;
      checks.reliability-checklist = checklist;
    };
}
