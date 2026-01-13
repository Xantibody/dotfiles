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

  # Custom plugins that need to be built from source
  customPlugins = {
    skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "skkeleton";
      src = pkgs.fetchFromGitHub {
        owner = "vim-skk";
        repo = "skkeleton";
        rev = "3e019b331fbf9bd1d4539e7bd650a1c543125cee";
        sha256 = "sha256-VDu8WypgpzY+Dd8KIPJXsvtBEwt5YiuGXn6HAUKCbIQ=";
      };
    };

    blink-cmp-skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-skkeleton";
      src = pkgs.fetchFromGitHub {
        owner = "Xantibody";
        repo = "blink-cmp-skkeleton";
        rev = "main";
        sha256 = "sha256-uzDqykavZlQcqLi/7Bqi72Pt/5zFdAqkyN73xm/KxFw=";
      };
    };

    blink-cmp-dictionary = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-dictionary";
      doCheck = false;
      src = pkgs.fetchFromGitHub {
        owner = "Kaiser-Yang";
        repo = "blink-cmp-dictionary";
        rev = "944b3b215b01303672d4213758db7c5c5a1e3c92";
        sha256 = "sha256-e8ucufhLdNnE8fBjSLaTJngEj1valYE9upH78y+wj4I=";
      };
    };

    smooth-cursor = pkgs.vimUtils.buildVimPlugin {
      name = "SmoothCursor-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "gen740";
        repo = "SmoothCursor.nvim";
        rev = "12518b284e1e3f7c6c703b346815968e1620bee2";
        sha256 = "sha256-P0jGm5ODEVbtmqPGgDFBPDeuOF49CFq5x1PzubEJgaM=";
      };
    };

    in-and-out = pkgs.vimUtils.buildVimPlugin {
      name = "in-and-out-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "ysmb-wtsg";
        repo = "in-and-out.nvim";
        rev = "03456b9c49365a28732378a7f2a72a613154e042";
        sha256 = "sha256-QPEvWOTKzscUs+vHQ0LJ/BNBd9buMgG/jkmjg7JlhT8=";
      };
    };

    tiny-code-action = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-code-action-nvim";
      doCheck = false;
      src = pkgs.fetchFromGitHub {
        owner = "rachartier";
        repo = "tiny-code-action.nvim";
        rev = "main";
        sha256 = "sha256-tiV+drfWAryw8cexSCgmZCXfHxi4oi6qX6oNmhHrhAk=";
      };
    };

    vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
      name = "vim-qfreplace";
      src = pkgs.fetchFromGitHub {
        owner = "thinca";
        repo = "vim-qfreplace";
        rev = "707a895f9f86eeed106f64da0bd9fa07b3cd9cee";
        sha256 = "sha256-6G89NznCOumLIJb2l8szKGIWMr3CtpeHUfdkzEOCo8U=";
      };
    };

    nvim-markdown = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-markdown";
      src = pkgs.fetchFromGitHub {
        owner = "ixru";
        repo = "nvim-markdown";
        rev = "master";
        sha256 = "sha256-wjYTO9WqdDEbH4L3dsHqOoeQf0y/Uo6WX94w/D4EuGU=";
      };
    };
  };
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
              # Dependencies
              plenary-nvim
              nvim-web-devicons
              mini-icons

              # File navigation
              telescope-nvim
              telescope-fzf-native-nvim
              oil-nvim
              fzf-lua

              # Git
              diffview-nvim
              neogit
              gitsigns-nvim

              # Syntax & parsing
              nvim-treesitter.withAllGrammars

              # UI
              barbar-nvim
              which-key-nvim
              mini-nvim
            ];

            display = with pkgs.vimPlugins; [
              # Status line
              lualine-nvim

              # Visual enhancements
              flash-nvim
              neoscroll-nvim
              alpha-nvim
              hlchunk-nvim
              nvim-hlslens
              quick-scope

              # Custom plugins
              customPlugins.smooth-cursor
            ];

            edit = with pkgs.vimPlugins; [
              # LSP
              nvim-lspconfig
              lsp_signature-nvim
              fidget-nvim
              lazydev-nvim
              snacks-nvim

              # Completion
              blink-cmp
              lspkind-nvim
              customPlugins.blink-cmp-skkeleton
              customPlugins.blink-cmp-dictionary

              # Snippets
              luasnip
              friendly-snippets

              # Formatting
              conform-nvim

              # Editing
              comment-nvim
              nvim-surround
              nvim-autopairs
              customPlugins.in-and-out
              customPlugins.tiny-code-action
              customPlugins.vim-qfreplace
            ];

            preview = with pkgs.vimPlugins; [
              markdown-preview-nvim
              render-markdown-nvim
              customPlugins.nvim-markdown
            ];

            colorscheme = with pkgs.vimPlugins; [
              nightfox-nvim
              everforest
            ];

            japanese = [
              pkgs.vimPlugins.denops-vim
              customPlugins.skkeleton
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
