{
  pkgs,
  ...
}:
{
  xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  # Enable CUPS to print documents.
  printing.enable = true;
  pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
  auto-cpufreq = {
    enable = true;
  };
  xremap = {
    userName = "raizawa";
    serviceMode = "system";
    config = {
      modmap = [
        {
          name = "change CapsLock key to ctl";
          remap = {
            CapsLock = "Ctrl_L";
          };
        }
      ];
      keymap = [
        {
          # Ctrl + HがどのアプリケーションでもBackspaceになるように変更
          name = "Ctrl+H should be enabled on all apps as BackSpace";
          remap = {
            C-h = "Backspace";
          };
          # 一部アプリケーション（ターミナルエミュレータ）を対象から除外
          application = {
            not = [
              "Alacritty"
              "Kitty"
              "Wezterm"
            ];
          };
        }
      ];
    };
  };
  fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-goodix;
    };
  };
  udev = {
    enable = true;
    extraRules = ''
      SUBSYSTEM=="usb", ATTR{idVendor}=="10a5", ATTR{idProduct}=="d805", MODE="0666"
    '';
  };
  upower = {
    enable = true;
  };
}
