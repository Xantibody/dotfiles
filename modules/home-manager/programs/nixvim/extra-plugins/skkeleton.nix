{ pkgs, ... }:
let
  skkeleton = pkgs.vimUtils.buildVimPlugin {
    name = "skkeleton";
    src = pkgs.fetchFromGitHub {
      owner = "vim-skk";
      repo = "skkeleton";
      rev = "3e019b331fbf9bd1d4539e7bd650a1c543125cee";
      sha256 = "sha256-VDu8WypgpzY+Dd8KIPJXsvtBEwt5YiuGXn6HAUKCbIQ=";
    };
  };
in
{
  # extraPlugins リストに登録
  extraPlugins = [
    skkeleton
  ];

  # skkeleton の初期設定（辞書のパス設定など）をここに書くと管理が楽です
  # extraConfigLua = ''
  #   vim.fn['skkeleton#config']({
  #     globalJisyo = '~/.skk/SKK-JISYO.L',
  #   })
  # '';
}
