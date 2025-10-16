{ pkgs }:
{
  enable = true;
  viAlias = true;
  vimAlias = true;
  defaultEditor = true;
  extraPackages = with pkgs; [
    tree-sitter
    fzf
    deno
    wordnet
    textlint

    #LSP
    basedpyright
    bash-language-server
    efm-langserver
    fish-lsp
    gopls
    lua-language-server
    nixd
    rust-analyzer
    tinymist
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server

    #formatter
    biome
    nixfmt
    rustfmt
    stylua
    yamlfmt
  ];
}
