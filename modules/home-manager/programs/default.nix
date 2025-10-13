{
  pkgs,
  isLinux,
}:
{
  alacritty = import ./alacritty.nix { inherit pkgs; };
  direnv = import ./direnv.nix;
  fastfetch = import ./fastfetch.nix;
  fish = import ./fish.nix { inherit pkgs; };
  git = import ./git.nix;
  neovim = import ./neovim.nix { inherit pkgs; };
  rofi = import ./rofi.nix { inherit isLinux; };
  starship = import ./starship.nix;
  waybar = import ./waybar.nix { inherit isLinux; };
  zellij = import ./zellij.nix;
  zoxide = import ./zoxide.nix;
  kitty = import ./kitty.nix;
  emacs = import ./emacs.nix;
  #  firefox = import ./firefox.nix;
}
