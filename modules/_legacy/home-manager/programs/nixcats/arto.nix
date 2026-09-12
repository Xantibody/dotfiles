# Arto plugin configuration (darwin-only)
{ pkgs, sources }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "arto-vim";
    inherit (sources.arto-vim) src;
  };

  extra = {
    arto_path = "${pkgs.arto}/Applications/Arto.app";
  };
}
