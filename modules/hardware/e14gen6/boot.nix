# ブートローダとカーネル。
{
  flake.modules.nixos.boot =
    { pkgs, ... }:
    {
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        kernelPackages = pkgs.linuxPackages_latest;
      };
    };
}
