{
  pkgs,
  hyprpanel,
  ...
}:
let
  username = "raizawa";
in {
  imports = [ hyprpanel.homeManagerModules.hyprpanel ];
  home = import ./home {inherit pkgs username;}; 
  programs = import ./programs {inherit pkgs;};
  wayland = import ./wayland.nix;
}
