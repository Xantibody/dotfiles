# 編集系プラグイン
{ pkgs, ... }:
{
  # LSP
  plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;
      lua_ls.enable = true;
      gopls.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      yamlls.enable = true;
      jsonls.enable = true;
      html.enable = true;
      bashls.enable = true;
      pyright.enable = true;
      tinymist.enable = true;
      typos_lsp.enable = true;
      ts_ls.enable = true;
      helm_ls.enable = true;
      denols.enable = true;
      efm.enable = true;
    };
  };

  # Blink-cmp
  plugins.blink-cmp = {
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
            components = {
              kind_icon = {
                text.__raw = ''
                  function(ctx)
                    local icon = ctx.kind_icon
                    if vim.tbl_contains({ "path" }, ctx.source_name) then
                      local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        icon = dev_icon
                      end
                    else
                      icon = require("lspkind").symbolic(ctx.kind, {
                        mode = "symbol",
                      })
                    end
                    return icon .. ctx.icon_gap
                  end
                '';
                highlight.__raw = ''
                  function(ctx)
                    local hl = ctx.kind_hl
                    if vim.tbl_contains({ "Path" }, ctx.source_name) then
                      local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        hl = dev_hl
                      end
                    end
                    return hl
                  end
                '';
              };
            };
          };
        };
      };
      sources = {
        default.__raw = ''
          function(ctx)
            if require("blink-cmp-skkeleton").is_enabled() then
              return { "skkeleton" }
            else
              return { "lsp", "path", "snippets", "buffer", "lazydev", "dictionary" }
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
            score_offset = -1;
            opts.dictionary_directories.__raw = ''{ vim.fn.expand("~/.config/nvim/dictionary") }'';
          };
        };
      };
      fuzzy.implementation = "prefer_rust_with_warning";
    };
  };

  # Comment
  plugins.comment.enable = true;

  # Conform
  plugins.conform-nvim = {
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
        rumdl = {
          command = "rumdl";
          args = [
            "fmt"
            "-"
            "--quiet"
          ];
          stdin = true;
        };
      };
      formatters_by_ft = {
        go = [ "gofmt" ];
        json = [ "gojq" ];
        just = [ "just" ];
        lua = [ "stylua" ];
        markdown = [ "rumdl" ];
        nix = [ "nixfmt" ];
        rust = [ "rustfmt" ];
        typst = [ "typstyle" ];
        yaml = [ "yamlfmt" ];
      };
    };
  };

  # Diffview (keymapsはLuaで設定)
  plugins.diffview = {
    enable = true;
    settings.enhanced_diff_hl = true;
  };

  # Fidget
  plugins.fidget.enable = true;

  # Luasnip
  plugins.luasnip = {
    enable = true;
    fromVscode = [ { } ];
  };

  # Friendly-snippets
  plugins.friendly-snippets.enable = true;

  # Treesj
  plugins.treesj.enable = true;

  # Lazydev
  plugins.lazydev.enable = true;

  # Lsp-signature
  plugins.lsp-signature.enable = true;

  ## mini-surround
  plugins.mini-surround = {
    enable = true;
    autoLoad = true;
  };

  # hop
  plugins.hop = {
    enable = true;
    package = pkgs.vimPlugins.hop-nvim;
  };

  keymaps =
    let
      mode = [
        "n"
        "x"
        "o"
      ];
      options = {
        silent = true;
        noremap = true;
      };
    in
    [
      {
        key = "s";
        action = "<cmd>HopWord<CR>";
        inherit mode options;
      }
      {
        key = "S";
        action = "<cmd>HopChar2<CR>";
        inherit mode options;
      }
    ];
}
