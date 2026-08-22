# git の author 名と ghq の default owner は同じ GitHub ハンドルなので
# 1 箇所で定義する。
let
  githubUser = "Xantibody";
in
{
  enable = true;
  signing = {
    format = "ssh";
    signByDefault = true;
    key = "~/.ssh/id_ed25519.pub";
  };
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
}
