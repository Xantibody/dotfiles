{ pkgs, ... }:
let
  # extraConfigLua を用途別に分割
  luaConfig = import ./lua { inherit pkgs; };
in
{
  enable = true;
  viAlias = true;
  vimAlias = true;
  defaultEditor = true;

  globals = {
    mapleader = " ";
    maplocalleader = "\\";
    barbar_auto_setup = false;
  };

  opts = {
    modifiable = true;
    encoding = "utf-8";
    fileencoding = "utf-8";
    expandtab = true;
    shiftwidth = 2;
    tabstop = 2;
    relativenumber = true;
    number = true;
    clipboard = "unnamedplus";
    termguicolors = true;
    spell = true;
    spelllang = [ "en_us" ];
    foldmethod = "expr";
    foldexpr = "v:lua.vim.treesitter.foldexpr()";
    foldtext = "v:lua.vim.treesitter.foldtext()";
    foldlevel = 1;
    guifont = "Explex Console NF";
    colorcolumn = "80,100,120";
    scrolloff = 5;
    sidescrolloff = 8;
    wrap = false;
    list = true;
    timeout = true;
    timeoutlen = 300;
  };

  # 用途別に分割した Lua 設定を結合
  extraConfigLua = luaConfig.all;

  colorschemes.nightfox = {
    enable = true;
    flavor = "dayfox";
  };

  keymaps = import ./keymaps.nix;
  plugins = import ./plugins { inherit pkgs; };
  extraPlugins = import ./extra-plugins { inherit pkgs; };

  extraPackages = with pkgs; [
    tree-sitter
    fzf
    deno
    wordnet

    # LSP
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
    typos-lsp
    helm-ls
    just-lsp
    vscode-json-languageserver

    # formatter
    biome
    nixfmt-rfc-style
    rustfmt
    stylua
    yamlfmt
    just-formatter
    gojq
  ];
}
