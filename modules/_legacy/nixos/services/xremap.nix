{
  enable = true;
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
            "alacritty"
            "kitty"
            "wezterm"
          ];
        };
      }
    ];
  };
}
