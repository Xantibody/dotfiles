{
  pkgs,
  ...
}:
{
  programs = import ./programs;
  boot = import ./boot { inherit pkgs; };
  i18n = import ./i18n { inherit pkgs; };
  services = import ./services { inherit pkgs; };
  nix = import ./nix;
  users = import ./users { inherit pkgs; };
  networking = import ./networking;
  time.timeZone = "Asia/Tokyo";
  hardware.pulseaudio.enable = false;
  security = import ./security;
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [ hackgen-nf-font ];
  environment = {
    etc."polkit-1/rules.d/50-fprintd.rules".text = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "net.reactivated.fprint.device.enroll" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    systemPackages = with pkgs; [
      neovim
      unzip
      fishPlugins.z
      slack
      docker
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
  };

}
