# Arto plugin configuration (darwin-only)
{ pkgs }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "arto-vim";
    src = pkgs.fetchFromGitHub {
      owner = "arto-app";
      repo = "arto.vim";
      # renovate: datasource=git-refs depName=arto-app/arto.vim
      rev = "5a00f0e977a035f8b098e0c4142e968a64f8efd2";
      sha256 = "sha256-/Rk/t7Hm/VTa1KQptzd+1sZIiRR2l++tA98DSe9uwV4=";
    };
  };

  extra = {
    arto_path = "${pkgs.arto}/Applications/Arto.app";
  };
}
