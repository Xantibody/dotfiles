# Lspkind - LSP補完アイコン
# blink-cmpの依存ライブラリ
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    lspkind-nvim
  ];
}
