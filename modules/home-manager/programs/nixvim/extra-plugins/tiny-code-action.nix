# 外部diff依存のモジュールがrequireチェックに失敗するためdoCheck無効
{ pkgs }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "tiny-code-action-nvim";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-XBVE8FJVUljRdF5G5iug+V+fVp/uaB4B4kfo4yvI+9w=";
    };
  };
  config = ''lua require("tiny-code-action").setup({})'';
}
