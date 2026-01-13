# nixCats-nvim configuration
# Migration from nixvim
# See: https://github.com/BirdeeHub/nixCats-nvim
{
  inputs,
  pkgs,
  ...
}:
let
  nixCats = inputs.nixCats;
  inherit (nixCats) utils;

  luaPath = ./lua;

  # Category definitions - organize plugins and tools by category
  categoryDefinitions =
    { pkgs, ... }:
    {
      # LSP servers and runtime dependencies
      lspsAndRuntimeDeps = {
        general = with pkgs; [
          tree-sitter
          fzf
          wordnet
        ];
        lsp = with pkgs; [
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
        ];
        formatters = with pkgs; [
          nixfmt-rfc-style
          rustfmt
          stylua
          just-formatter
          oxfmt
        ];
      };

      # Plugins loaded at startup
      startupPlugins = {
        core = with pkgs.vimPlugins; [
          plenary-nvim
          nvim-web-devicons
          telescope-nvim
          oil-nvim
          diffview-nvim
          neogit
          gitsigns-nvim
          nvim-treesitter.withAllGrammars
          barbar-nvim
          which-key-nvim
          mini-nvim
          fzf-lua
        ];
        display = with pkgs.vimPlugins; [
          flash-nvim
          lualine-nvim
          neoscroll-nvim
          alpha-nvim
          hlchunk-nvim
          nvim-hlslens
        ];
        edit = with pkgs.vimPlugins; [
          nvim-lspconfig
          blink-cmp
          luasnip
          friendly-snippets
          conform-nvim
          comment-nvim
          nvim-surround
          nvim-autopairs
          lsp_signature-nvim
          lazydev-nvim
          fidget-nvim
          lspkind-nvim
          nvim-cmp # for compatibility
        ];
        preview = with pkgs.vimPlugins; [
          markdown-preview-nvim
          render-markdown-nvim
        ];
        colorscheme = with pkgs.vimPlugins; [
          nightfox-nvim
        ];
        japanese = with pkgs.vimPlugins; [
          skkeleton
          denops-vim
        ];
      };

      # Optional plugins (lazy-loaded)
      optionalPlugins = { };

      # Environment variables
      environmentVariables = { };

      # Extra wrapper args
      extraWrapperArgs = { };

      # Lua packages
      extraLuaPackages = { };
    };

  # Package definitions
  packageDefinitions = {
    nvim =
      { pkgs, ... }:
      {
        settings = {
          wrapRc = true;
          aliases = [
            "vim"
            "vi"
          ];
        };

        # Enable all categories
        categories = {
          general = true;
          lsp = true;
          formatters = true;
          core = true;
          display = true;
          edit = true;
          preview = true;
          colorscheme = true;
          japanese = true;
        };
      };
  };

  defaultPackageName = "nvim";
in
{
  imports = [
    (nixCats.utils.mkNixCatsModuleExport.homeModule inputs {
      inherit
        categoryDefinitions
        packageDefinitions
        defaultPackageName
        luaPath
        ;
    })
  ];

  nixCats = {
    enable = true;
    packageNames = [ "nvim" ];
  };
}
