{
  enable = true;
  overwrite.enable = true;
  hyprland.enable = true;
  settings = {
    layout = {
      "bar.layouts" =
        let
          layout =
            {
              showBattery ? true,
            }:
            {
              "left" = [
                "dashboard"
                "workspaces"
                "windowtitle"
                "updates"
                "storage"
              ] ++ (if showBattery then [ "battery" ] else [ ]);
              "middle" = [
                "media"
              ];
              "right" = [
                "cpu"
                "ram"
                "volume"
                "network"
                "bluetooth"
                "systray"
                "clock"
                "notifications"
              ];
            };
          none = {
            "left" = [ ];
            "middle" = [ ];
            "right" = [ ];
          };
        in
        {
          "0" = layout { };
          "1" = none;
          "2" = layout { showBattery = false; };
          "3" = none;
        };
    };
    theme = {
      bar = {
        floating = false;
        buttons.modules.ram.enableBorder = false;
        buttons.enableBorders = true;
        transparent = true;
      };
      font.size = "14px";
    };
    bar = {
      clock.format = "%y/%m/%d  %H:%M";
      media.show_active_only = true;
      media.format = "{title}";
      notifications.show_total = false;
      #launcher.autoDetectIcon = true;
      launcher.icon = "";
      battery.hideLabelWhenFull = true;
      customModules = {
        updates = {
          pollingInterval = 1440000;
          updateCommand = "jq '[.[].cvssv3_basescore | to_entries | add | select(.value > 5)] | length' <<< $(vulnix -S --json)";
          icon.updated = "󰋼";
          icon.pending = "󰋼";
        };
      };
      volume = {
        rightClick = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        middleClick = "pavucontrol";
      };
    };
    menus = {
      clock = {
        time.military = true;
        time.hideSeconds = false;
        weather.enabled = false;
      };
      dashboard = {
        controls.enabled = false;
        shortcuts.enabled = true;
        shortcuts.right.shortcut1.command = "gcolor3";
      };
      media.displayTime = true;
      power.lowBatteryNotification = true;
    };
  };
}
