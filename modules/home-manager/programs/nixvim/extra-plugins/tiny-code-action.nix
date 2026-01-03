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
      sha256 = "sha256-tiV+drfWAryw8cexSCgmZCXfHxi4oi6qX6oNmhHrhAk=";
    };
  };
  config = ''lua require("tiny-code-action").setup({})'';
}
