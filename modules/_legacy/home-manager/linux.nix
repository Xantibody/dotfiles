# Linux のデスクトップ側だけで要る home-manager 設定。
# 以前は default.nix が pkgs.stdenv.isLinux で分岐していたが、module の属性名が
# pkgs に依存すると _module.args の解決で無限再帰になるので、host が選ぶ形にした。
{ config, ... }:
{
  wayland = import ./wayland.nix { inherit config; };
  services = import ./services;
}
