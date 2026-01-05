# 全プラグインを結合
{ pkgs, ... }:
{
  imports = [
    ./core.nix
    ./display.nix
    ./display  # Display関連プラグイン (新しいモジュール構造)
    ./edit.nix
    ./edit  # Edit関連プラグイン (新しいモジュール構造)
    ./git  # Git関連プラグイン
    ./navigation  # Navigation関連プラグイン
    ./preview.nix
    ./keymaps.nix
  ];
}
