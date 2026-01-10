# Plenary - 共通ライブラリ
# telescope, neogit, diffview等の依存ライブラリ
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    plenary-nvim
  ];
}
