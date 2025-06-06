{
  pkgs,
  ...
}:
{
  enable = true;
  settings = {
    window = {
      option_as_alt = "Both";
      #startup_mode = "fullscreen"
    };
    font = {
      size = 13;
      normal = {
        family = "Explex Console NF";
        style = "Regular";
      };
    };
    env = {
      TERM = "alacritty";
    };
    terminal = {
      shell = "fish";
    };
    general.import = [ pkgs.alacritty-theme.dawnfox ];
  };
}
