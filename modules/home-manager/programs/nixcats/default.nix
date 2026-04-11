# nixCats-nvim configuration
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
  isDarwin = pkgs.stdenv.isDarwin;
  arto = import ./arto.nix { inherit pkgs; };

  # Custom plugins that need to be built from source
  customPlugins = {
    skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "skkeleton";
      src = pkgs.fetchFromGitHub {
        owner = "vim-skk";
        repo = "skkeleton";
        # renovate: datasource=git-refs depName=vim-skk/skkeleton
        rev = "b530eac5a859ce2f8fa4d99fa5cd83b9d3199086";
        sha256 = "sha256-OhHlG3ngNbvUSNqS/MFJpYI/cfbkxSxTPo8EiSwW/MU=";
      };
    };

    blink-cmp-skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-skkeleton";
      src = pkgs.fetchFromGitHub {
        owner = "Xantibody";
        repo = "blink-cmp-skkeleton";
        # renovate: datasource=git-refs depName=Xantibody/blink-cmp-skkeleton
        rev = "69edc70d5003e0a3e9a5fc396d9a2f3049f03873";
        sha256 = "sha256-zEghDbOZtUQrwSLh7B7w/IxmsLML/Dju7yJP38/VMog=";
      };
    };

    blink-cmp-dictionary = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-dictionary";
      doCheck = false;
      src = pkgs.fetchFromGitHub {
        owner = "Kaiser-Yang";
        repo = "blink-cmp-dictionary";
        # renovate: datasource=git-refs depName=Kaiser-Yang/blink-cmp-dictionary currentValue=master
        rev = "35142bba869b869715e91a99d2f46bcf93fca4ae";
        sha256 = "sha256-idDHERqdqKB8/we00oVEo1sTDqrwPRTsuWmmG0ISeoE=";
      };
    };

    smooth-cursor = pkgs.vimUtils.buildVimPlugin {
      name = "SmoothCursor-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "gen740";
        repo = "SmoothCursor.nvim";
        # renovate: datasource=git-refs depName=gen740/SmoothCursor.nvim
        rev = "12518b284e1e3f7c6c703b346815968e1620bee2";
        sha256 = "sha256-P0jGm5ODEVbtmqPGgDFBPDeuOF49CFq5x1PzubEJgaM=";
      };
    };

    in-and-out = pkgs.vimUtils.buildVimPlugin {
      name = "in-and-out-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "ysmb-wtsg";
        repo = "in-and-out.nvim";
        # renovate: datasource=git-refs depName=ysmb-wtsg/in-and-out.nvim currentValue=master
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
        # renovate: datasource=git-refs depName=rachartier/tiny-code-action.nvim
        rev = "1c75d7e121ea38bf362d939ddb9064ca9bb6884f";
        sha256 = "sha256-PAwpKpvPOJuqN6XNWSQTQ14XF3aalZ2HXqx2mugzC5I=";
      };
    };

    vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
      name = "vim-qfreplace";
      src = pkgs.fetchFromGitHub {
        owner = "thinca";
        repo = "vim-qfreplace";
        # renovate: datasource=git-refs depName=thinca/vim-qfreplace currentValue=master
        rev = "707a895f9f86eeed106f64da0bd9fa07b3cd9cee";
        sha256 = "sha256-6G89NznCOumLIJb2l8szKGIWMr3CtpeHUfdkzEOCo8U=";
      };
    };

    nvim-markdown = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-markdown";
      src = pkgs.fetchFromGitHub {
        owner = "ixru";
        repo = "nvim-markdown";
        # renovate: datasource=git-refs depName=ixru/nvim-markdown currentValue=master
        rev = "37850581fdaec153ce84af677d43bf8fce60813a";
        sha256 = "sha256-wjYTO9WqdDEbH4L3dsHqOoeQf0y/Uo6WX94w/D4EuGU=";
      };
    };

    tiny-inline-diagnostic = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-inline-diagnostic-nvim";
      doCheck = false;
      src = pkgs.fetchFromGitHub {
        owner = "rachartier";
        repo = "tiny-inline-diagnostic.nvim";
        # renovate: datasource=git-refs depName=rachartier/tiny-inline-diagnostic.nvim
        rev = "57a0eb84b2008c76e77930639890d9874195b1e1";
        sha256 = "sha256-mJl6yuTH79QsfKRktBGzPOlnL1x3/KoOAWyDGGw/AwM=";
      };
    };

    tiny-glimmer = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-glimmer-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "rachartier";
        repo = "tiny-glimmer.nvim";
        # renovate: datasource=git-refs depName=rachartier/tiny-glimmer.nvim
        rev = "932e6c2cc4a43ce578f007db1f8f61ad6798f938";
        sha256 = "sha256-Lgdeu3xRXKf7YcuPKPnVvECzQR+RzC0bM+AiilHLLVg=";
      };
    };

    # Dogfooding: external diff integration branch
    neogit = pkgs.vimUtils.buildVimPlugin {
      name = "neogit";
      src = pkgs.fetchFromGitHub {
        owner = "Xantibody";
        repo = "neogit";
        # renovate: datasource=git-refs depName=Xantibody/neogit currentValue=master
        rev = "73870229977fdd8747025820e15e98cfde787b9c";
        sha256 = "sha256-tvIJEHv/R8I1W3FBAwZHmn92JgiibqQtR75V9wQFSsE=";
      };
      checkInputs = [ pkgs.vimPlugins.diffview-nvim ];
      dependencies = [ pkgs.vimPlugins.plenary-nvim ];
      nvimSkipModules = [
        "neogit.integrations.diffview"
        "neogit.popups.diff.actions"
        "neogit.popups.diff.init"
      ];
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
              ichigyo-ls
              fish-lsp
              gopls
              helm-ls
              just-lsp
              lua-language-server
              nixd
              rust-analyzer
              tinymist
              typescript-go
              typos-lsp
              vscode-langservers-extracted
              yaml-language-server
            ];
            formatters = with pkgs; [
              mdsf
              nixfmt
              oxfmt
              rustfmt
              stylua
              just-formatter
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
              customPlugins.neogit
              gitsigns-nvim

              # Syntax & parsing
              nvim-treesitter
              nvim-treesitter.withAllGrammars

              # UI
              barbar-nvim
              which-key-nvim
              mini-nvim
            ];

            display =
              (with pkgs.vimPlugins; [
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
                customPlugins.tiny-glimmer
              ])
              # AI visualization (darwin-only)
              ++ lib.optionals isDarwin [ arto.plugin ];

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
              customPlugins.in-and-out
              customPlugins.tiny-code-action
              customPlugins.tiny-inline-diagnostic
              customPlugins.vim-qfreplace
            ];

            preview = with pkgs.vimPlugins; [
              markdown-preview-nvim
              render-markdown-nvim
              customPlugins.nvim-markdown
            ];

            colorscheme = with pkgs.vimPlugins; [
              nightfox-nvim
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

            extra = lib.optionalAttrs isDarwin arto.extra;

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
