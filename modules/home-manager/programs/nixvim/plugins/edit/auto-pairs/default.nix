# Auto-pairs - 自動括弧補完
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    auto-pairs
  ];
}
