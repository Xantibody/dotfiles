# 全プラグインを結合
{ pkgs, ... }:
{
  imports = [
    ./core.nix
    ./core  # Core関連プラグイン (新しいモジュール構造)
    ./display.nix
    ./display  # Display関連プラグイン (新しいモジュール構造)
    ./edit.nix
    ./edit  # Edit関連プラグイン (新しいモジュール構造)
    ./preview.nix
    ./keymaps.nix
  ];
}
