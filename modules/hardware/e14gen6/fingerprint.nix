# 指紋センサ。ThinkPad E14 Gen6 の Goodix は tod ドライバ経由でしか動かない。
{
  flake.modules.nixos.fingerprint =
    { pkgs, ... }:
    {
      services.fprintd = {
        enable = true;
        tod = {
          enable = true;
          driver = pkgs.libfprint-2-tod1-goodix;
        };
      };

      security.pam.services = {
        login.fprintAuth = true;
        sudo.fprintAuth = true;
      };

      # 指紋の登録は root でなく wheel から行いたい
      environment.etc."polkit-1/rules.d/50-fprintd.rules".text = ''
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
