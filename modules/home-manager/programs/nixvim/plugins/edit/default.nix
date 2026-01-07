# 編集関連プラグインの集約
{
  imports = [
    # 依存ライブラリ
    ./lspkind
    # LSP・補完
    ./lsp
    ./lsp-signature
    ./blink-cmp
    ./blink-cmp-dictionary
    ./blink-cmp-skkeleton
    ./luasnip
    ./friendly-snippets
    ./lazydev
    # フォーマット・編集
    ./conform
    ./comment
    ./surround
    ./auto-pairs
    ./in-and-out
    # LSP拡張・ヘルパー
    ./fidget
    ./helm-ls
    ./tiny-code-action
    # ナビゲーション
    ./quick-scope
    ./vim-qfreplace
  ];
}
