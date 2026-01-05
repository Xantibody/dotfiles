# Conform フォーマッター
{ pkgs, ... }:
{
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

  # Format toggle keymap
  keymaps = [
    {
      key = "<C-F>";
      action = "<CMD>FormatToggle<CR>";
      mode = [
        "n"
        "i"
      ];
      options = {
        noremap = true;
        silent = true;
        desc = "toggle save format";
      };
    }
  ];
}
