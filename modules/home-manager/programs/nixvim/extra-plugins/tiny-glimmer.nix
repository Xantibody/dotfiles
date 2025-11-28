# testディレクトリがrequireチェックに失敗するためdoCheck無効
{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "tiny-glimmer-nvim";
  doCheck = false;
  src = pkgs.fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-glimmer.nvim";
    rev = "d508ef41b5a58bc5f068a487868d7fb990ff2df5";
    sha256 = "sha256-HqL8F1grXrdeS0rflFaq4eIo0PsLtjNA3rUW5XmBnpk=";
  };
}
