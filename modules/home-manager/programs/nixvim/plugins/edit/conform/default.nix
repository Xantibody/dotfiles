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
      };
      formatters_by_ft = {
        css = [ "oxfmt" ];
        go = [ "gofmt" ];
        html = [ "oxfmt" ];
        javascript = [ "oxfmt" ];
        javascriptreact = [ "oxfmt" ];
        json = [ "oxfmt" ];
        json5 = [ "oxfmt" ];
        jsonc = [ "oxfmt" ];
        just = [ "just" ];
        jvascriptreact = [ "oxfmt" ];
        lua = [ "stylua" ];
        markdown = [ "oxfmt" ];
        mdx = [ "oxfmt" ];
        nix = [ "nixfmt" ];
        rust = [ "rustfmt" ];
        toml = [ "oxfmt" ];
        typescript = [ "oxfmt" ];
        typst = [ "typstyle" ];
        yaml = [ "oxfmt" ];
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
