{pkgs,...}:{
  enable = true;
  settings = {
    window = {
      option_as_alt = "Both";
      #startup_mode = "fullscreen"
    };
    font = {
      size = 14.0;
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
    general.import = [ pkgs.alacritty-theme.cyber_punk_neon] ;
  };
}
