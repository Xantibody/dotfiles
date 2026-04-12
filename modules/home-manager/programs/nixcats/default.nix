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
  sources = pkgs.callPackage ../../../../_sources/generated.nix { };
  arto = import ./arto.nix { inherit pkgs sources; };

  # Custom plugins built from nvfetcher-managed sources
  customPlugins = {
    skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "skkeleton";
      inherit (sources.skkeleton) src;
    };

    blink-cmp-skkeleton = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-skkeleton";
      inherit (sources.blink-cmp-skkeleton) src;
    };

    blink-cmp-dictionary = pkgs.vimUtils.buildVimPlugin {
      name = "blink-cmp-dictionary";
      doCheck = false;
      inherit (sources.blink-cmp-dictionary) src;
    };

    smooth-cursor = pkgs.vimUtils.buildVimPlugin {
      name = "SmoothCursor-nvim";
      inherit (sources.smooth-cursor) src;
    };

    in-and-out = pkgs.vimUtils.buildVimPlugin {
      name = "in-and-out-nvim";
      inherit (sources.in-and-out) src;
    };

    tiny-code-action = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-code-action-nvim";
      doCheck = false;
      inherit (sources.tiny-code-action) src;
    };

    vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
      name = "vim-qfreplace";
      inherit (sources.vim-qfreplace) src;
    };

    nvim-markdown = pkgs.vimUtils.buildVimPlugin {
      name = "nvim-markdown";
      inherit (sources.nvim-markdown) src;
    };

    tiny-inline-diagnostic = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-inline-diagnostic-nvim";
      doCheck = false;
      inherit (sources.tiny-inline-diagnostic) src;
    };

    tiny-glimmer = pkgs.vimUtils.buildVimPlugin {
      name = "tiny-glimmer-nvim";
      inherit (sources.tiny-glimmer) src;
    };

    # Dogfooding: external diff integration branch
    neogit = pkgs.vimUtils.buildVimPlugin {
      name = "neogit";
      inherit (sources.neogit) src;
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
