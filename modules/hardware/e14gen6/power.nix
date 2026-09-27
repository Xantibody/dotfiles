# バッテリーと電力。センサ読みとバッテリー残量の取得もここ。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  # 残量が少ない・満充電になったときに 1 度だけ通知する。waybar の battery モジュールは
  # 色が変わるだけで、画面を見ていなければ気付けない。
  # 元は mechabar 付属の battery-level.sh で、同じ timer を手で張る前提だった
  flake.modules.homeManager.power =
    { pkgs, ... }:
    let
      batteryLevel = pkgs.writeShellApplication {
        name = "battery-level";
        runtimeInputs = with pkgs; [
          upower
          libnotify
          gawk
        ];
        text = ''
          warning=20
          critical=10

          bat=$(upower -e | grep BAT | head -n 1)
          state=$(upower -i "$bat" | awk '/state:/ {print $2}')
          level=$(upower -i "$bat" | awk '/percentage:/ {print $2}' | tr -d '%')

          # 同じ状態で通知を繰り返さないための印。再起動で消えてよいので runtime dir に置く
          mark="$XDG_RUNTIME_DIR/battery-level"
          mkdir -p "$mark"

          case "$state" in
            discharging) rm -f "$mark/full" ;;
            charging) rm -f "$mark/warning" "$mark/critical" ;;
          esac

          if [ "$state" = fully-charged ] && [ ! -e "$mark/full" ]; then
            notify-send -a state -i battery-full -r 9991 \
              "Battery Charged (''${level}%)" "You might want to unplug your PC."
            touch "$mark/full"
          elif [ "$state" = discharging ] && [ "$level" -le "$critical" ] && [ ! -e "$mark/critical" ]; then
            notify-send -a state -u critical -i battery-empty -r 9991 \
              "Battery Critical (''${level}%)" "Plug in your PC now."
            touch "$mark/critical" "$mark/warning"
          elif [ "$state" = discharging ] && [ "$level" -le "$warning" ] && [ ! -e "$mark/warning" ]; then
            notify-send -a state -u critical -i battery-caution -r 9991 \
              "Battery Low (''${level}%)" "You might want to plug in your PC."
            touch "$mark/warning"
          fi
        '';
      };
    in
    {
      systemd.user.services.battery-level = {
        Unit.Description = "Notify on low or full battery";
        Service = {
          Type = "oneshot";
          ExecStart = "${batteryLevel}/bin/battery-level";
        };
      };
      systemd.user.timers.battery-level = {
        Unit.Description = "Check the battery level every minute";
        Timer = {
          OnActiveSec = "1min";
          OnUnitActiveSec = "1min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };

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
      home-manager.sharedModules = [ hm.power ];
    };
}
