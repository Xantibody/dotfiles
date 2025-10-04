{ isLinux }:
{
  mako = {
    enable = isLinux;
    settings = {
      icons = true;
      markup = true;
      default-timeout = 5000;
    };
  };
  hyprpaper = {
    enable = isLinux;
  };
  hypridle = import ./hypridle.nix { inherit isLinux; };
}
