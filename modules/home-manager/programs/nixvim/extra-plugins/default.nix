# NixVim未サポート/extraPluginsで管理するプラグイン
{ pkgs, ... }:
with pkgs.vimPlugins;
[
  # nixpkgs
  alpha-nvim
  auto-pairs
  denops-vim
  hlchunk-nvim
  lspkind-nvim
  nvim-hlslens
  nvim-web-devicons
  plenary-nvim
  quick-scope

  # custom
  (import ./skkeleton.nix { inherit pkgs; })
  (import ./key-menu.nix { inherit pkgs; })
  (import ./smooth-cursor.nix { inherit pkgs; })
  (import ./tiny-glimmer.nix { inherit pkgs; })
  (import ./blink-cmp-dictionary.nix { inherit pkgs; })
  (import ./blink-cmp-skkeleton.nix { inherit pkgs; })
  (import ./in-and-out.nix { inherit pkgs; })
  (import ./tiny-code-action.nix { inherit pkgs; })
  (import ./vim-qfreplace.nix { inherit pkgs; })
  (import ./snacks.nix { inherit pkgs; })
  (import ./helm-ls.nix { inherit pkgs; })
]
