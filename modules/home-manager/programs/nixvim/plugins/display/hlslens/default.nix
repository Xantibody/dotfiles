# Hlslens - 検索結果表示
# lua/hlslens.lua で設定
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    nvim-hlslens
  ];
}
