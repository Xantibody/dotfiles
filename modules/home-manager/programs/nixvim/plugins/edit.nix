# 編集系プラグイン (LSPは edit/lsp/, 補完は edit/completion/ に移動済み)
{ pkgs, ... }:
{
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

  # Lsp-signature
  plugins.lsp-signature.enable = true;

  ## nvim-surround
  plugins.nvim-surround = {
    enable = true;
    autoLoad = true;
  };

  # Flash
  imports = [ ./flash.nix ];

  # Hlslens は extraPlugins で管理 (NixVim未サポート)
}
