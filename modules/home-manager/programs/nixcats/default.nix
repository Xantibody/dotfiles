# nixCats-nvim configuration
# Migration from nixvim
# See: https://github.com/BirdeeHub/nixCats-nvim
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  utils = inputs.nixCats.utils;
in
{
  imports = [
    inputs.nixCats.homeModule
  ];

  config = {
    nixCats = {
      enable = true;

      addOverlays = [
        (utils.standardPluginOverlay inputs)
      ];

      packageNames = [ "nvim" ];

      luaPath = ./lua;

      # Category definitions
      categoryDefinitions.replace =
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkPlugin,
          ...
        }@packageDef:
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
              nodePackages.vscode-json-languageserver
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
            ];
            preview = with pkgs.vimPlugins; [
              markdown-preview-nvim
              render-markdown-nvim
            ];
            colorscheme = with pkgs.vimPlugins; [
              nightfox-nvim
            ];
            japanese = [
              pkgs.vimPlugins.denops-vim
              # skkeleton - built from source
              (pkgs.vimUtils.buildVimPlugin {
                name = "skkeleton";
                src = pkgs.fetchFromGitHub {
                  owner = "vim-skk";
                  repo = "skkeleton";
                  rev = "3e019b331fbf9bd1d4539e7bd650a1c543125cee";
                  sha256 = "sha256-VDu8WypgpzY+Dd8KIPJXsvtBEwt5YiuGXn6HAUKCbIQ=";
                };
              })
            ];
          };

          # Optional plugins (lazy-loaded)
          optionalPlugins = { };

          # Environment variables
          environmentVariables = { };

          # Extra wrapper args
          extraWrapperArgs = { };
        };

      # Package definitions
      packageDefinitions.replace = {
        nvim =
          { pkgs, name, ... }:
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
    };
  };
}
