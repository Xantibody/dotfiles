# nixCats で組む neovim。プラグイン、LSP、フォーマッタ、lua 設定が全部ここに乗る。
# See: https://github.com/BirdeeHub/nixCats-nvim
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    # ichigyo-ls は自作の LSP で、使うのは neovim だけ
    nixpkgs.overlays = [
      (final: _prev: {
        ichigyo-ls = inputs.ichigyo-ls.packages.${final.stdenv.hostPlatform.system}.default;
      })
    ];
    home-manager.sharedModules = [ hm.neovim ];
  };
in
{
  flake.modules.darwin.neovim = share;
  flake.modules.nixos.neovim = share;

  flake.modules.homeManager.neovim =
    { lib, pkgs, ... }:
    let
      utils = inputs.nixCats.utils;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      sources = pkgs.callPackage ../../_sources/generated.nix { };

      # AI の作業を可視化する Arto (darwin のみ)。本体は modules/ai/arto.nix。
      arto = {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "arto-vim";
          inherit (sources.arto-vim) src;
        };
        extra.arto_path = "${pkgs.arto}/Applications/Arto.app";
      };

      # blink-cmp-dictionary が読む英単語リスト。以前は 4.7 MB の words.txt を
      # repo に置いて ~/.config/nvim/dictionary へ symlink していた。
      dictionary = pkgs.runCommand "nvim-dictionary" { } ''
        mkdir -p $out
        cp ${pkgs.scowl}/share/dict/wamerican.95 $out/words.txt
      '';

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
      imports = [ inputs.nixCats.homeModule ];

      config.nixCats = {
        enable = true;

        addOverlays = [
          (utils.standardPluginOverlay inputs)
        ];

        packageNames = [ "nvim" ];

        luaPath = ./neovim/lua;

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
                typescript
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

            # Plugins on the runtimepath from the start: the loader itself and
            # libraries that other plugins require without a packadd.
            startupPlugins = {
              core = with pkgs.vimPlugins; [
                lze
                plenary-nvim
                nvim-web-devicons
                mini-icons
                mini-nvim
                fzf-lua
                nvim-treesitter
                nvim-treesitter.withAllGrammars
              ];

              # AI visualization (darwin-only)
              display = lib.optionals isDarwin [ arto.plugin ];

              edit = with pkgs.vimPlugins; [
                # LSP configs are read from lsp/ on the runtimepath
                nvim-lspconfig
                lsp_signature-nvim
                snacks-nvim

                # blink.cmp sources and icons
                lspkind-nvim
                customPlugins.blink-cmp-skkeleton
                customPlugins.blink-cmp-dictionary
                friendly-snippets

                customPlugins.vim-qfreplace
              ];

              colorscheme = with pkgs.vimPlugins; [
                nightfox-nvim
              ];
            };

            # Plugins packadd-ed by lze on first use (see lua/config/plugins/init.lua)
            optionalPlugins = {
              core = with pkgs.vimPlugins; [
                # File navigation
                telescope-nvim
                telescope-fzf-native-nvim
                oil-nvim

                # Git
                diffview-nvim
                customPlugins.neogit
                gitsigns-nvim

                # UI
                barbar-nvim
                which-key-nvim
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
                customPlugins.tiny-glimmer
              ];

              edit = with pkgs.vimPlugins; [
                # LSP
                fidget-nvim
                lazydev-nvim

                # Completion
                blink-cmp

                # Snippets
                luasnip

                # Formatting
                conform-nvim

                # Editing
                comment-nvim
                customPlugins.in-and-out
                customPlugins.tiny-code-action
                customPlugins.tiny-inline-diagnostic
              ];

              preview = with pkgs.vimPlugins; [
                markdown-preview-nvim
                render-markdown-nvim
                customPlugins.nvim-markdown
              ];

              japanese = [
                pkgs.vimPlugins.denops-vim
                customPlugins.skkeleton
              ];
            };

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

              extra = {
                dictionary_dir = "${dictionary}";
              }
              // lib.optionalAttrs isDarwin arto.extra;

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
