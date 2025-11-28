# 全プラグインを結合
{ pkgs, ... }:
let
  core = import ./core.nix { inherit pkgs; };
  display = import ./display.nix { inherit pkgs; };
  edit = import ./edit.nix { inherit pkgs; };
  preview = import ./preview.nix { inherit pkgs; };
in
core // display // edit // preview
