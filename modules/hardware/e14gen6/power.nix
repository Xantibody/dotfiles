# バッテリーと電力。センサ読みとバッテリー残量の取得もここ。
{
  flake.modules.nixos.power =
    { pkgs, ... }:
    {
      services.auto-cpufreq.enable = true;
      services.upower.enable = true;
      environment.systemPackages = with pkgs; [
        lm_sensors
        iw
        usbutils
      ];
    };
}
