# git と、その周りで普段使う CLI。
# author 名と ghq の default owner は同じ GitHub ハンドルなので 1 箇所で定義する。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  githubUser = "Xantibody";
in
{
  flake.modules.homeManager.git =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        delta
        difftastic
        gh
        ghq
      ];

      my.shell.abbr = {
        g = {
          cmd = "git";
          desc = "git 本体";
        };
        ga = {
          cmd = "git add";
          desc = "変更をステージ";
        };
        gc = {
          cmd = "git commit";
          desc = "コミット";
        };
        gp = {
          cmd = "git pull";
          desc = "リモートを取り込む";
        };
        gP = {
          cmd = "git push";
          desc = "リモートへ送る（大文字は取り消しにくい操作の印）";
        };
        gs = {
          cmd = "git status";
          desc = "作業ツリーの状態";
        };
      };

      programs.git = {
        enable = true;
        signing = {
          format = "ssh";
          signByDefault = true;
          key = "~/.ssh/id_ed25519.pub";
        };
        # AI セッション用の作業ディレクトリ (~/.claude/CLAUDE.md の Repository
        # Conventions 参照)。全リポジトリで無視したいので各 .gitignore ではなく
        # global ignore (~/.config/git/ignore) に置く。
        ignores = [
          ".ai/"
          # home-manager 管理前の ~/.config/git/ignore に Claude Code が書いていた行。
          # ファイルを store のシンボリックリンクに置き換えるので、ここで引き継ぐ。
          "**/.claude/settings.local.json"
        ];
        settings = {
          user = {
            name = githubUser;
            email = "zeku.bushinryu38@gmail.com";
          };
          core.editor = "nvim";
          init.defaultBranch = "main";
          push.useForceIfIncludes = true;
          ghq = {
            # 最後の root が primary となり、新規 clone 先になる。
            # 会社 org は host 側の ghq.<url>.root で work へ振り分ける。
            root = [
              "~/Repository/work"
              "~/Repository/private"
            ];
            user = githubUser;
          };
        };
      };
    };

  flake.modules.darwin.git = {
    home-manager.sharedModules = [ hm.git ];
  };

  flake.modules.nixos.git = {
    programs.git.enable = true;
    home-manager.sharedModules = [ hm.git ];
  };
}
