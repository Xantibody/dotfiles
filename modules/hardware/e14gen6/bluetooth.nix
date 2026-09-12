# Bluetooth。bluetui は TUI のペアリング用。
{
  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      environment.systemPackages = [ pkgs.bluetui ];
    };
}
