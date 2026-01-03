# nixvim側にある
# blink.cmp依存のためdoCheck無効
{ pkgs, ... }:
let
  # プラグインのビルド定義を内部で変数化
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "blink-cmp-dictionary";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "Kaiser-Yang";
      repo = "blink-cmp-dictionary";
      rev = "944b3b215b01303672d4213758db7c5c5a1e3c92";
      sha256 = "sha256-e8ucufhLdNnE8fBjSLaTJngEj1valYE9upH78y+wj4I=";
    };
  };
in
{
  # NixVimのModule Systemに載せるための設定
  extraPlugins = [ plugin ];

  # 必要であれば、ここにLuaの設定（config）も一緒に書ける
  # extraConfigLua = '' ... '';
}
