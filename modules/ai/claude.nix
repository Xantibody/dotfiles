# Claude Code。設定ファイルの実体は configs/claude/ にあり、home.file で配る。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.claude ];
  };
in
{
  flake.modules.homeManager.claude = {
    home.file = {
      ".claude/CLAUDE.md".source = ../../configs/claude/CLAUDE.md;
      ".claude/settings.json".source = ../../configs/claude/settings.json;
      ".claude/skills" = {
        source = ../../configs/claude/skills;
        recursive = true;
      };
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
      ccD = {
        cmd = "claude --dangerously-skip-permissions";
        desc = "権限確認をすべて飛ばす（危険）";
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
