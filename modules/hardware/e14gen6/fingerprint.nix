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
    };
}
