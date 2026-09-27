# キーの読み替え。CapsLock を Ctrl に、Ctrl+H を BackSpace に。PageUp / PageDown は殺す。
{ inputs, ... }:
{
  flake.modules.nixos.remap =
    { config, ... }:
    {
      imports = [ inputs.xremap.nixosModules.default ];

      services.xremap = {
        enable = true;
        userName = config.my.user.name;
        # アプリごとの除外 (application.not) は、xremap がフォーカス中のウィンドウを
        # 知れて初めて効く。Hyprland で窓を取れるのは user モード + wlroots だけで、
        # system モードの頃は除外が黙って無視されていた
        serviceMode = "user";
        withWlroots = true;
        config = {
          modmap = [
            {
              name = "change CapsLock key to ctl";
              remap = {
                CapsLock = "Ctrl_L";
              };
            }
            {
              # 矢印キーの隣にあって、押し間違えるとページが飛ぶ
              name = "disable PageUp and PageDown";
              remap = {
                PageUp = [ ];
                PageDown = [ ];
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
              # 一部アプリケーション（ターミナルエミュレータ）を対象から除外。
              # 名前は Wayland の app_id
              application = {
                not = [
                  "Alacritty"
                  "kitty"
                  "org.wezfurlong.wezterm"
                ];
              };
            }
          ];
        };
      };
    };
}
