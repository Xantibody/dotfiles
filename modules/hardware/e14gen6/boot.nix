# ブートローダとカーネル。
{
  flake.modules.nixos.boot =
    { pkgs, ... }:
    {
      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            # ESP は 512 MB 程度しかなく、世代ごとの kernel と initrd で埋まる
            configurationLimit = 10;
          };
          efi.canTouchEfiVariables = true;
        };
        kernelPackages = pkgs.linuxPackages_latest;
      };
    };
}
