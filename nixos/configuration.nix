{
  pkgs,
  ...
}:
{
  programs = import ./programs;
  boot = import ./boot { inherit pkgs; };
  i18n = import ./i18n { inherit pkgs; };
  services = import ./services;
  nix = import ./nix;
  users = import ./users { inherit pkgs; };
  networking = import ./networking;
  time.timeZone = "Asia/Tokyo";
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [ hackgen-nf-font ];
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
