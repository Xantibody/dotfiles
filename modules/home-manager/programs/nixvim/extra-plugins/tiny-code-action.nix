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
      sha256 = "sha256-lEKl7W99akV71vfdHxVLwk1Py272SrT0/cH2y3COXpw=";
    };
  };
  config = ''lua require("tiny-code-action").setup({})'';
}
