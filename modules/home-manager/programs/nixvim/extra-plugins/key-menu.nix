# linty-org -> emmanueltouzery fork (元リポジトリ削除)
{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "key-menu-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "emmanueltouzery";
    repo = "key-menu.nvim";
    rev = "171ad5c40fe978ebba86026beac1ac3ed8eda42d";
    sha256 = "sha256-Nh6pXd0UxLlD6BsOge8I2Rh8Gyt8VmxL7tVIca0ozj8=";
  };
}
