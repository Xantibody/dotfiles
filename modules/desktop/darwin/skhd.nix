# skhd。macOS でホットキーからコマンドを叩く。キーの割り当ては叩く先の機能のファイルが
# services.skhd.skhdConfig に足す。
# Hyper (ctrl+alt+shift+cmd) は左 Control を OmniWM の Hyper トリガーにして押す。
# トリガーで作った Hyper は skhd にも 4 修飾として届くので Karabiner は要らない。
{
  flake.modules.darwin.skhd = {
    services.skhd.enable = true;
  };
}
