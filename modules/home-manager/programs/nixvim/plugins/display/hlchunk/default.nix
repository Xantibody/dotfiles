# Hlchunk - インデント可視化
# lua/plugins.lua で設定
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    hlchunk-nvim
  ];
}
