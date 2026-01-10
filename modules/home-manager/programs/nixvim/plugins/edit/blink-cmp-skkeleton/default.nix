{ pkgs, ... }:
let
  # 変数としてプラグインのビルド定義を分離
  blink-cmp-skkeleton = pkgs.vimUtils.buildVimPlugin {
    name = "blink-cmp-skkeleton";
    src = pkgs.fetchFromGitHub {
      owner = "Xantibody";
      repo = "blink-cmp-skkeleton";
      rev = "main";
      sha256 = "sha256-uzDqykavZlQcqLi/7Bqi72Pt/5zFdAqkyN73xm/KxFw=";
    };
  };
in
{
  # NixVim の設定として登録
  extraPlugins = [
    blink-cmp-skkeleton
  ];

  # 今後、補完ソースの登録などの Lua 設定が必要になったらここに追加できる
  # extraConfigLua = '' ... '';
}
