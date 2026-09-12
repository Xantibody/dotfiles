{
  enable = true;
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
        on-resume = "hyprctl dispatch dpms on"; # 何か入力が来たら点灯
      } # 5分でロック
      {
        timeout = 600;
        on-timeout = "hyprctl dispatch dpms off";
        on-resume = "hyprctl dispatch dpms on"; # 解除時は必ず点灯
      } # 10分で消灯
    ];
  };
}
