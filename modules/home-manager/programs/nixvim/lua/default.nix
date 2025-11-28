# extraConfigLua を用途別に管理
{ pkgs, ... }:
let
  ui = import ./ui.nix;
  utils = import ./utils.nix;
  lsp = import ./lsp.nix;
  skkeleton = import ./skkeleton.nix;
  hlslens = import ./hlslens.nix;
  keymenu = import ./keymenu.nix;
  plugins = import ./plugins.nix;
  alpha = import ./alpha.nix;
in
{
  # 全ての Lua 設定を結合
  all = builtins.concatStringsSep "\n\n" [
    "-- UI settings"
    ui
    "-- Utils module"
    utils
    "-- LSP configuration"
    lsp
    "-- Skkeleton configuration"
    skkeleton
    "-- Hlslens configuration"
    hlslens
    "-- Key-menu configuration"
    keymenu
    "-- Plugin setup (extraPlugins)"
    plugins
    "-- Alpha (dashboard) configuration"
    alpha
  ];

  # 個別にアクセスしたい場合用
  inherit
    ui
    utils
    lsp
    skkeleton
    hlslens
    keymenu
    plugins
    alpha
    ;
}
