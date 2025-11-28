# tiny-code-action依存, 外部コマンド依存のモジュールがrequireチェックに失敗するためdoCheck無効
{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "snacks-nvim";
  doCheck = false;
  src = pkgs.fetchFromGitHub {
    owner = "folke";
    repo = "snacks.nvim";
    rev = "main";
    sha256 = "sha256-vRedYg29QGPGW0hOX9qbRSIImh1d/SoDZHImDF2oqKM=";
  };
}
