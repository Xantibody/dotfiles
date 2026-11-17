# skill の validator (configs/agents/skills/skill-authoring/scripts/validate) を CI で回す check。
# 手で回すだけだと、改名で残った参照や隠した skill への hand-off が次に誰かが回すまで見つからない。
# 全 skill に -offline -strict でかけ、configs/agents/README.md の図が skill の dir と揃っているかも見る。
# validator 自身の go test は buildGoModule の checkPhase が回す。
{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      validate = pkgs.buildGoModule {
        pname = "skill-validate";
        version = "0.1.0";
        src = ../../configs/agents/skills/skill-authoring/scripts/validate;
        vendorHash = null;
        # eval の commit hash を引くテストに使う。無ければそのテストは skip になる
        nativeCheckInputs = [ pkgs.git ];
        meta.mainProgram = "validate";
      };
    in
    {
      # sandbox には ~/.claude/skills が無いので、flake input が配る skill は -known で渡す。
      # AIDEV-NOTE: my.skills は home-manager の option で perSystem からは読めないので、input の skill dir を直接並べる。本文が新しい外の skill を読み込んだらここに足す
      # AIDEV-NOTE: self に .git は入らないので eval の commit hash はここでは見ない (validator が note を出す)。手元で回したときだけ検査される
      checks.skills = pkgs.runCommand "skills" { } ''
        dirs=()
        for f in ${self}/configs/agents/skills/*/SKILL.md ${self}/configs/media/skills/*/SKILL.md; do
          dirs+=("''${f%/SKILL.md}")
        done
        ${pkgs.lib.getExe validate} -offline -strict \
          -readme ${self}/configs/agents/README.md \
          -known ${inputs.osekkai}/skills/osekkai \
          -known ${inputs.ha}/skills/ha \
          "''${dirs[@]}"
        touch $out
      '';
    };
}
