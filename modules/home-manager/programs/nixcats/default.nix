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
        rev = "3e019b331fbf9bd1d4539e7bd650a1c543125cee";
        sha256 = "sha256-VDu8WypgpzY+Dd8KIPJXsvtBEwt5YiuGXn6HAUKCbIQ=";
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
        # renovate: datasource=git-refs depName=Kaiser-Yang/blink-cmp-dictionary
        rev = "944b3b215b01303672d4213758db7c5c5a1e3c92";
        sha256 = "sha256-e8ucufhLdNnE8fBjSLaTJngEj1valYE9upH78y+wj4I=";
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
        # renovate: datasource=git-refs depName=ysmb-wtsg/in-and-out.nvim
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
        rev = "2215a7311b6eac9535695167c3a38d10c3eab444";
        sha256 = "sha256-c3wH7Zwy0oChAuyDToHHJWOOvEALtl9FDDKNcdCCTd8=";
      };
    };

    vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
      name = "vim-qfreplace";
      src = pkgs.fetchFromGitHub {
        owner = "thinca";
        repo = "vim-qfreplace";
        # renovate: datasource=git-refs depName=thinca/vim-qfreplace
        rev = "707a895f9f86eeed106f64da0bd9fa07b3cd9cee";
        sha256 = "sha256-6G89NznCOumLIJb2l8szKGIWMr3CtpeHUfdkzEOCo8U=";
      };
    };

    nvim-markdown = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-markdown";
      src = pkgs.fetchFromGitHub {
        owner = "ixru";
        repo = "nvim-markdown";
        # renovate: datasource=git-refs depName=ixru/nvim-markdown
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
        rev = "ecce93ff7db4461e942c03e0fcc64bd785df4057";
        sha256 = "sha256-KWUyn6fJDQ+jSBdO9gwN9mmufgIALwjm5GboK6y5ksM=";
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
        # renovate: datasource=git-refs depName=Xantibody/neogit
        rev = "ec664733e7c871714578d5a9599d863ea7cbd12f";
        sha256 = "sha256-YwTcuoR/G+5tIJjq5bwkNBL/OUPjAC0jc7R+SdHsULk=";
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
              efm-langserver
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
              nodePackages.vscode-json-languageserver
              vscode-langservers-extracted
              yaml-language-server
            ];
            formatters = with pkgs; [
              nixfmt
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
