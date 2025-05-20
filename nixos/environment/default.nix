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
    kdePackages.dolphin
    wofi
    wl-clipboard
    usbutils
    jq
    vulnix
    zathura
  ];
}
