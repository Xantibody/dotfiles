{
  pkgs,
  hyprpanel,
  ...
}:
{
  imports = [ hyprpanel.homeManagerModules.hyprpanel ];
  home = rec {
    username = "raizawa";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
    file = import ./home/file { inherit pkgs; };
    packages = import ./home/packages { inherit pkgs; };
  };
  programs = {
    git = import ./programs/git;
    neovim = import ./programs/neovim { inherit pkgs; };
    hyprpanel = import ./programs/hyperpanel;
    alacritty = import ./programs/alacritty { inherit pkgs; };
    direnv = import ./programs/direnv;
    starship = import ./programs/starship;
  };
  wayland = import ./wayland;
}
