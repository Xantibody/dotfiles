{ pkgs, ... }:
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
    clipboard = "unnamedplus";
    colorcolumn = "80,100,120";
    encoding = "utf-8";
    expandtab = true;
    fileencoding = "utf-8";
    foldexpr = "v:lua.vim.treesitter.foldexpr()";
    foldmethod = "expr";
    foldtext = "v:lua.vim.treesitter.foldtext()";
    foldlevel = 99;
    foldlevelstart = 99;
    guifont = "Explex Console NF";
    list = true;
    modifiable = true;
    number = true;
    relativenumber = true;
    scrolloff = 5;
    shiftwidth = 2;
    sidescrolloff = 8;
    spell = true;
    spelllang = [ "en_us" ];
    tabstop = 2;
    termguicolors = true;
    timeout = true;
    timeoutlen = 300;
    wrap = false;
  };

  # Lua設定ファイルを ~/.config/nvim/lua/ に配置
  extraFiles = {
    "lua/config/utils.lua".source = ./lua/utils.lua;
    "lua/config/ui.lua".source = ./lua/ui.lua;
    "lua/config/lsp.lua".source = ./lua/lsp.lua;
    "lua/config/skkeleton.lua".source = ./lua/skkeleton.lua;
    "lua/config/hlslens.lua".source = ./lua/hlslens.lua;
    "lua/config/plugins.lua".source = ./lua/plugins.lua;
    "lua/config/alpha.lua".source = ./lua/alpha.lua;
  };

  # Lua設定を読み込む
  extraConfigLua = ''
    require("config.utils")
    require("config.ui")
    require("config.lsp")
    require("config.skkeleton")
    require("config.hlslens")
    require("config.plugins")
    require("config.alpha")
  '';

  colorschemes.nightfox = {
    enable = true;
    flavor = "dayfox";
  };

  imports = [
    ./plugins
    ./extra-plugins
  ];

  extraPackages = with pkgs; [
    tree-sitter
    fzf
    wordnet

    # LSP
    basedpyright
    bash-language-server
    deno
    efm-langserver
    fish-lsp
    gopls
    helm-ls
    just-lsp
    lua-language-server
    nixd
    rust-analyzer
    tinymist
    typescript-language-server
    typos-lsp
    vscode-json-languageserver
    vscode-langservers-extracted
    yaml-language-server

    # formatter
    biome
    nixfmt-rfc-style
    rustfmt
    stylua
    yamlfmt
    just-formatter
    gojq
    rumdl
  ];
}
