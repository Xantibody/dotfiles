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
  };
}
