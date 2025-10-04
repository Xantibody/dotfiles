{ isLinux }:
{
  enable = isLinux;
  settings = {
    general = {
      lock_cmd = "pidof hyprlock || hyprlock";
      before_sleep_cmd = "loginctl lock-session";
      after_sleep_cmd = "hyprctl dispatch dpms on";
    };
    listener = [
      {
        timeout = 300;
        on-timeout = "hyprlock";
      } # 5分でロック
      {
        timeout = 600;
        on-timeout = "hyprctl dispatch dpms off";
      } # 10分で消灯
    ];
  };
}
