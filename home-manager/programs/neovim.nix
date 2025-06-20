{ pkgs }:
{
  enable = true;

  viAlias = true;
  vimAlias = true;
  defaultEditor = true;
  extraPackages = with pkgs; [
    tree-sitter
    biome

    #LSP
    basedpyright
    bash-language-server
    efm-langserver
    gopls
    lua-language-server
    nixd
    rust-analyzer
    tinymist
    typescript-language-server
    vscode-langservers-extracted

    #formatter
    nixfmt
    stylua
    yamlfmt
  ];
}
