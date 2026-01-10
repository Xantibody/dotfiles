{ pkgs, ... }:
let
  nvim-markdown = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-markdown";
    src = pkgs.fetchFromGitHub {
      owner = "ixru";
      repo = "nvim-markdown";
      rev = "master"; # 特定のコミットハッシュにする場合はここを書き換えてください
      sha256 = "sha256-wjYTO9WqdDEbH4L3dsHqOoeQf0y/Uo6WX94w/D4EuGU=";
    };
  };
in
{
  # extraPlugins への登録
  extraPlugins = [
    nvim-markdown
  ];

  # このプラグインはグローバル変数 (vim.g) で設定を行うのが一般的です
  extraConfigLua = ''
    -- リストの自動挿入を有効にする (1: 有効, 0: 無効)
    vim.g.vim_markdown_auto_insert_bullets = 1
    -- 改行時に新しいリスト項目を作成
    vim.g.vim_markdown_new_list_item_indent = 0
    -- 折りたたみの設定 (0で無効)
    vim.g.vim_markdown_folding_disabled = 1
    -- TOC（目次）の設定
    vim.g.vim_markdown_toc_autofit = 1
  '';
}
