# 編集系プラグイン (LSP, 補完, フォーマットは edit/ 配下に移動済み)
{ pkgs, ... }:
{
  # Comment
  plugins.comment.enable = true;

  # Diffview (keymapsはLuaで設定)
  plugins.diffview = {
    enable = true;
    settings.enhanced_diff_hl = true;
  };

  # Fidget
  plugins.fidget.enable = true;

  # Lsp-signature
  plugins.lsp-signature.enable = true;

  ## nvim-surround
  plugins.nvim-surround = {
    enable = true;
    autoLoad = true;
  };

  # Flash
  imports = [ ./flash.nix ];

  # Hlslens は extraPlugins で管理 (NixVim未サポート)
}
