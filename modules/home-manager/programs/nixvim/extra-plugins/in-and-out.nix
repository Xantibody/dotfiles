{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "in-and-out-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "ysmb-wtsg";
    repo = "in-and-out.nvim";
    rev = "03456b9c49365a28732378a7f2a72a613154e042";
    sha256 = "sha256-QPEvWOTKzscUs+vHQ0LJ/BNBd9buMgG/jkmjg7JlhT8=";
  };
}
