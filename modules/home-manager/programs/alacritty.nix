{ pkgs, ... }:
{
  enable = true;
  settings = {
    window = {
      option_as_alt = "Both";
    };
    font = {
      size = 13;
      normal = {
        family = "Explex35 Console NF";
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
