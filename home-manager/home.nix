{ 
pkgs, 
hyprpanel,
... }:{
  imports = [ hyprpanel.homeManagerModules.hyprpanel ];
  home = rec {
    username = "raizawa";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
    file  = import ./file {inherit pkgs;};
    packages = import ./packages {inherit pkgs;};
    };
  programs = {
    git = import ./programs/git;
    neovim = import ./programs/neovim {inherit pkgs;};
    hyprpanel = import ./programs/hyperpanel;
    };
    wayland = import ./wayland;
}

