{
  pkgs,
  ...
}:
{
  enable = true;
  defaultEditor = true; # $EDITOR=nvimに設定
  viAlias = true;
  vimAlias = true;
  extraPackages = with pkgs; [
    biome
    nodejs_23
    go

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
  ];
}
