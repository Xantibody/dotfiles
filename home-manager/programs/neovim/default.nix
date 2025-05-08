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
    wl-clipboard
    go
    pnpm_9
    textlint
    textlint-rule-preset-ja-technical-writing


    #LSP
    rust-analyzer
    efm-langserver
    lua-language-server
    gopls
    typescript-language-server
  ];
}
