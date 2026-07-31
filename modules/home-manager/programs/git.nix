{
  enable = true;
  signing = {
    format = "ssh";
    signByDefault = true;
    key = "~/.ssh/id_ed25519.pub";
  };
  settings = {
    user = {
      name = "Xantibody";
      email = "zeku.bushinryu38@gmail.com";
    };
    core.editor = "nvim";
    push.useForceIfIncludes = true;
    # 最後の root が primary となり、新規 clone 先になる。
    # 会社 org は host 側の ghq.<url>.root で work へ振り分ける。
    ghq.root = [
      "~/Repository/work"
      "~/Repository/private"
    ];
  };
}
