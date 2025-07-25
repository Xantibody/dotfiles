{ pkgs, ... }:
{
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

    # waybar
    bluetui
    brightnessctl
    coreutils
    gawk
    iw
    kitty
    libnotify
    lm_sensors
    networkmanager
    playerctl
    pulseaudio
    waybar
    wireplumber
    claude-code
  ];
}
