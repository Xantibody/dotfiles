# Quick-scope - 移動補助
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    quick-scope
  ];
}
