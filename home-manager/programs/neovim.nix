{
  pkgs,
}:
{
  enable = true;

  viAlias = true;
  vimAlias = true;
  defaultEditor = true;
  extraPackages = with pkgs; [
    tree-sitter
    biome
    nodejs_23

    #LSP
    rust-analyzer
    efm-langserver
    lua-language-server
    gopls
    typescript-language-server
    nixd
    basedpyright
    vscode-langservers-extracted
    bash-language-server
    tinymist
  ];
}
