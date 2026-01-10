# Alpha - ダッシュボード
# lua/alpha.lua で設定
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    alpha-nvim
  ];
}
