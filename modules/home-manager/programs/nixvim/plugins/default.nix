# 全プラグインを結合
{ pkgs, ... }:
{
  imports = [
    ./core.nix
    ./display.nix
    ./edit.nix
    ./preview.nix
    ./keymaps.nix
  ];
}
