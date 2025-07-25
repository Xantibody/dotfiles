{ pkgs, ... }: {
  xserver = import ./xserver.nix;
  printing = import ./printing.nix;
  pipewire = import ./pipewire.nix;
  auto-cpufreq = import ./auto-cpufreq.nix;
  xremap = import ./xremap.nix;
  fprintd = import ./fprintd.nix { inherit pkgs; };
  udev = import ./udev.nix;
  upower = import ./upower.nix;
}