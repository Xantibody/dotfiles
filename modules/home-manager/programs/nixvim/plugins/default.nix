# 全プラグインを結合
{ pkgs, ... }:
{
  imports = [
    ./core  # Core関連プラグイン (telescope, oil, diffview, neogit, gitsigns, treesitter, barbar, etc.)
    ./display  # Display関連プラグイン (flash, lualine, neoscroll, tiny-glimmer)
    ./edit  # Edit関連プラグイン (lsp, blink-cmp, luasnip, conform, comment, surround, etc.)
    ./preview  # Preview関連プラグイン (markdown-preview, render-markdown)
    ./keymaps.nix  # グローバルkeymaps
  ];
}
