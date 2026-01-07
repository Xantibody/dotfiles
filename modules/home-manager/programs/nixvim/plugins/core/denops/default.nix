# Denops - Denoベースプラグインライブラリ
# skkeletonの依存ライブラリ
{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    denops-vim
  ];
}
