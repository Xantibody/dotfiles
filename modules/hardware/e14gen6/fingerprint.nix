# 指紋センサ。ThinkPad E14 Gen6 のセンサは FPC (10a5:d805) で、libfprint 本体の fpcmoc が扱う。
# PAM の fprintAuth は fprintd を有効にした時点で全サービスの既定値が true になる。
{
  flake.modules.nixos.fingerprint =
    { pkgs, ... }:
    {
      # AIDEV-NOTE: tod (Goodix の blob) は載せない。この機体は FPC で、tod 版 libfprint は本体より古い
      services.fprintd.enable = true;

      # 指紋の登録は root でなく wheel から、パスワード入力なしで行いたい (既定は auth_self_keep)
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "net.reactivated.fprint.device.enroll" &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';

      # センサの保存領域が埋まると登録できなくなる (libfprint#415)。
      # script/delete_device_fprint.py で消すにはユーザから触れる必要がある。
      # 0666 で全員に開けず、uaccess でログイン中のユーザにだけ渡す。uaccess は 73-seat-late
      # で処理されるので、99-local.rules に入る extraRules では遅すぎて効かない
      services.udev.packages = [
        (pkgs.writeTextDir "etc/udev/rules.d/70-fpc-sensor.rules" ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="10a5", ATTR{idProduct}=="d805", TAG+="uaccess"
        '')
      ];
    };
}
