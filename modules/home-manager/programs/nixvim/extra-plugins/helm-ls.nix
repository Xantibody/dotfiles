{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "helm-ls-nvim";
  src = pkgs.fetchFromGitHub {
    owner = "qvalentin";
    repo = "helm-ls.nvim";
    rev = "main";
    sha256 = "sha256-W9NRa84l5Cs62OsDeqb+LMxk8oYjhVBCB3o3UmE9a0I=";
  };
}
