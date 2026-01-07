# NixVim未サポート/extraPluginsで管理するプラグイン
{ pkgs, ... }:
{
  # custom
  imports = [
    ./skkeleton.nix
    ./smooth-cursor.nix
    ./blink-cmp-dictionary.nix
    ./blink-cmp-skkeleton.nix
    ./in-and-out.nix
    ./tiny-code-action.nix
    ./vim-qfreplace.nix
    ./helm-ls.nix
    ./nvim-markdown.nix
  ];

  extraPlugins = with pkgs.vimPlugins; [
    # nixpkgs
    alpha-nvim
    auto-pairs
    denops-vim
    hlchunk-nvim
    lspkind-nvim
    nvim-hlslens
    plenary-nvim
    quick-scope
    # nvim-web-devicons - plugins/core/web-devicons/ で管理
    # which-key-nvim - plugins/core/which-key/ で管理
  ];
}
