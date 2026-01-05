# 編集系プラグイン (LSP, 補完, フォーマット, コメント等は edit/ 配下に移動済み)
# (Diffviewは git/ に移動済み)
{ pkgs, ... }:
{
  # Lsp-signature
  plugins.lsp-signature.enable = true;

  # Flash は display/ に移動済み

  # Hlslens は extraPlugins で管理 (NixVim未サポート)
}
