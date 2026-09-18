# Claude Code。設定ファイルの実体は configs/claude/ にあり、home.file で配る。
# Claude が画面を見るための agent-browser (headless Chrome の CLI) もここに置く。
# 手順は configs/claude/skills/browser-verify にあり、上流の使い方 skill は本体が同梱している。
# Chrome 本体は store に無く、初回に `agent-browser install` が Chrome for Testing を落とす。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    # AIDEV-NOTE: agent-browser は nixpkgs にもあるが上流の更新が速く、llm-agents.nix の方が追従が早い
    nixpkgs.overlays = [
      inputs.llm-agents.overlays.shared-nixpkgs
      (import ../../overlays/textlint-rules.nix)
    ];
    home-manager.sharedModules = [
      hm.claude
      hm.textlint
    ];
  };
in
{
  # PR / issue 本文の lint。同じ feature だがファイルは分ける (perSystem の check まで持つ)
  imports = [ ./_textlint.nix ];

  flake.modules.homeManager.claude =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.llm-agents.agent-browser ];

      home.file = {
        ".claude/CLAUDE.md".source = ../../configs/claude/CLAUDE.md;
        ".claude/settings.json".source = ../../configs/claude/settings.json;
        ".claude/skills" = {
          source = ../../configs/claude/skills;
          recursive = true;
        };
        # AIDEV-NOTE: ha と同じく configs/claude/skills にコピーしない。package の版と skill の版が常に揃う
        ".claude/skills/agent-browser".source =
          "${pkgs.llm-agents.agent-browser}/share/agent-browser/skills/agent-browser";
        ".claude/statusline.sh" = {
          source = ../../configs/claude/statusline.sh;
          executable = true;
        };
      };

      my.shell.abbr = {
        cc = {
          cmd = "claude";
          desc = "Claude Code";
        };
        ccp = {
          cmd = "claude --permission-mode plan";
          desc = "plan mode で起動";
        };
        ccA = {
          cmd = "claude --permission-mode auto";
          desc = "auto mode で起動。権限を自動判断させる";
        };
      };
    };

  flake.modules.darwin.claude = share;

  flake.modules.nixos.claude = {
    imports = [ share ];
    # Claude Code のネイティブインストーラが落とす汎用 Linux バイナリは interpreter が
    # /lib64/ld-linux-x86-64.so.2 固定で、FHS でない NixOS ではそのままだと起動できない。
    # nix-ld はその位置に shim を置くので、自動更新で新しいバイナリが落ちてきても効き続ける。
    # AIDEV-NOTE: patchelf は自動更新のたびに壊れ、pkgs.claude-code も自前更新で同じ問題に戻るので採らない
    # 必要な libstdc++ / zlib / openssl はモジュールのデフォルト libraries に含まれている。
    programs.nix-ld.enable = true;
  };
}
