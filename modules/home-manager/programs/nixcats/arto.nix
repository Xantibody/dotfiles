# Arto plugin configuration (darwin-only)
{ pkgs }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "arto-vim";
    src = pkgs.fetchFromGitHub {
      owner = "arto-app";
      repo = "arto.vim";
      # renovate: datasource=git-refs depName=arto-app/arto.vim
      rev = "b05936238ff835ceca43442bf4ab8e843e73815c";
      sha256 = "sha256-/Rk/t7Hm/VTa1KQptzd+1sZIiRR2l++tA98DSe9uwV4=";
    };
  };

  extra = {
    arto_path = "${pkgs.arto}/Applications/Arto.app";
  };
}
