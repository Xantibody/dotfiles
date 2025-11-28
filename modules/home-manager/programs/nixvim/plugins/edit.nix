# 編集系プラグイン: blink-cmp, comment, conform, diffview, fidget, luasnip, treesj, lazydev, lsp-signature
{ pkgs, ... }:
{
  # Blink-cmp
  blink-cmp = {
    enable = true;
    settings = {
      keymap.preset = "super-tab";
      snippets.preset = "luasnip";
      appearance.nerd_font_variant = "mono";
      completion = {
        documentation = {
          auto_show = true;
          window.border = "rounded";
        };
        ghost_text.enabled = true;
        menu = {
          border = "rounded";
          draw = {
            columns.__raw = ''{ { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } }'';
            treesitter = [ "lsp" ];
          };
        };
      };
      sources = {
        default.__raw = ''
          function(ctx)
            if require("blink-cmp-skkeleton").is_enabled() then
              return { "skkeleton" }
            else
              return { "dictionary", "lazydev", "lsp", "path", "snippets", "buffer" }
            end
          end
        '';
        providers = {
          lazydev = {
            name = "LazyDev";
            module = "lazydev.integrations.blink";
            score_offset = 1;
          };
          skkeleton = {
            name = "skkeleton";
            module = "blink-cmp-skkeleton";
            score_offset = 100;
            min_keyword_length = 0;
          };
          dictionary = {
            module = "blink-cmp-dictionary";
            name = "Dict";
            min_keyword_length = 3;
            # snippets以下にしたいので低いスコア
            score_offset = -1;
            opts.dictionary_directories.__raw = ''{ vim.fn.expand("~/.config/nvim/dictionary") }'';
          };
        };
      };
      fuzzy.implementation = "prefer_rust_with_warning";
    };
  };

  # Comment
  comment.enable = true;

  # Conform
  conform-nvim = {
    enable = true;
    settings = {
      format_on_save = {
        __raw = ''
          function(bufnr)
            if _G.utils.is_autoformat_enabled() then
              return {
                timeout_ms = 500,
                lsp_format = "fallback",
              }
            end
          end
        '';
      };
      formatters = {
        typstyle.command = "typstyle";
      };
      formatters_by_ft = {
        go = [ "gofmt" ];
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        rust = [ "rustfmt" ];
        typst = [ "typstyle" ];
        yaml = [ "yamlfmt" ];
        just = [ "just" ];
        json = [ "gojq" ];
      };
    };
  };

  # Diffview
  diffview = {
    enable = true;
    settings.enhanced_diff_hl = true;
  };

  # Fidget
  fidget.enable = true;

  # Luasnip
  luasnip = {
    enable = true;
    fromVscode = [ { } ];
  };

  # Friendly-snippets
  friendly-snippets.enable = true;

  # Treesj
  treesj.enable = true;

  # Lazydev
  lazydev.enable = true;

  # Lsp-signature
  lsp-signature.enable = true;
}
