# skhd。macOS でホットキーからコマンドを叩く。キーの割り当ては叩く先の機能のファイルが
# services.skhd.skhdConfig に足す。
# Hyper (ctrl+alt+shift+cmd) は Karabiner が左 Control から作る (karabiner.nix)。
{ inputs, ... }:
{
  flake.modules.darwin.skhd =
    { pkgs, ... }:
    {
      services.skhd = {
        enable = true;
        # 素の skhd は bundle の外の実行ファイルなので、アクセシビリティの許可が
        # /nix/store のパスに付き、rebuild で skhd が入れ替わるたびに取り直しになる
        package = (pkgs.callPackage inputs.nix-mac-app-identity { }).mkAppBundle {
          package = pkgs.skhd;
          identifier = "com.koekeishiya.skhd";
        };
      };
    };
}
