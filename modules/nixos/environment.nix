{ pkgs, ... }:
{
  etc = {
    "polkit-1/rules.d/50-fprintd.rules".text = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "net.reactivated.fprint.device.enroll" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
    "1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
      ''; # or just "zen" if you use unwrapped package
      mode = "0755";
    };
  };
  systemPackages = with pkgs; [
    cliphist
    gcc
    gimp3
    kdePackages.dolphin
    slack
    unzip
    usbutils
    wl-clipboard
    wofi
    xsel
    via

    bluetui
    brightnessctl
    coreutils
    gawk
    iw
    libnotify
    lm_sensors
    networkmanager
    playerctl
    pulseaudio
    waybar
    wireplumber
    hyprlock
  ];
}
