{ pkgs, ... }:
let
  # プラグインのビルド定義を変数に格納
  helm-ls-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "helm-ls-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "qvalentin";
      repo = "helm-ls.nvim";
      rev = "main";
      sha256 = "sha256-W9NRa84l5Cs62OsDeqb+LMxk8oYjhVBCB3o3UmE9a0I=";
    };
  };
in
{
  # extraPlugins リストに登録
  extraPlugins = [
    helm-ls-nvim
  ];

  # LSPの設定などが必要な場合はここに記述可能
  # plugins.lsp.servers.helm_ls.enable = true;
}
