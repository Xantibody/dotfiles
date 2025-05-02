{ 
  pkgs, 
  ... 
}:
{
  programs = import ./programs;
  boot = import ./boot;
  i18n = import ./i18n;
  services = import ./services;
  nix = import ./nix;
  users = import ./users {inherit pkgs;};
  networking.hostName = "nixos"; # Define your hostname.
  time.timeZone = "Asia/Tokyo";
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;
fonts.packages = with pkgs; [hackgen-nf-font];
  environment.systemPackages = with pkgs; [
    alacritty
    neovim
    unzip
    fishPlugins.z
    slack
    docker
    mise
    deno
    xsel
    fzf
    tree-sitter
    gcc
    clang
    zig
    starship
    kdePackages.dolphin
    wofi
  ];

}
