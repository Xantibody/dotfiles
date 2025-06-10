{
  pkgs,
  ...
}:
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
    clang
    deno
    fishPlugins.z
    fzf
    gcc
    gimp3
    jq
    kdePackages.dolphin
    slack
    unzip
    usbutils
    vulnix
    wl-clipboard
    wofi
    xsel
  ];
}
