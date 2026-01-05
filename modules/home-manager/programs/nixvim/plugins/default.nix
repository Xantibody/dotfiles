# 全プラグインを結合
{ pkgs, ... }:
{
  imports = [
    ./core.nix
    ./display.nix
    ./edit.nix
    ./edit  # 新しいモジュール構造
    ./preview.nix
    ./keymaps.nix
  ];
}
