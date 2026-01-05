# 編集系プラグイン (LSP, 補完, フォーマット, コメントは edit/ 配下に移動済み)
{ pkgs, ... }:
{
  # Diffview (keymapsはLuaで設定)
  plugins.diffview = {
    enable = true;
    settings.enhanced_diff_hl = true;
  };

  # Fidget
  plugins.fidget.enable = true;

  # Lsp-signature
  plugins.lsp-signature.enable = true;

  # Flash
  imports = [ ./flash.nix ];

  # Hlslens は extraPlugins で管理 (NixVim未サポート)
}
