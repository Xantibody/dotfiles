{
  mako = {
    enable = true;
    settings = {
      icons = true;
      markup = true;
      default-timeout = 5000;
    };
  };
  hyprpaper = {
    enable = true;
  };
  hypridle = import ./hypridle.nix;
}
