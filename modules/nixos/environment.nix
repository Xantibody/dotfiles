{ pkgs, ... }:
{
  etc."polkit-1/rules.d/50-fprintd.rules".text = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "net.reactivated.fprint.device.enroll" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';
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

    # waybar
    bluetui
    brightnessctl
    wireplumber
    networkmanager
    libnotify
    coreutils
    gawk
    lm_sensors
    kitty
    playerctl
    pulseaudio
  ];
}
