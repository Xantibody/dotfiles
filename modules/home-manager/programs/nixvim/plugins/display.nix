# 表示系プラグイン: alpha, flash, hlslens, lualine, neoscroll, nightfox, render-markdown
{ pkgs, ... }:
{
  # Alpha (dashboard)
  # extraPlugins + extraConfigLuaで設定（NixVimのalphaはconfigを上書きするため無効）

  # Lualine
  plugins.lualine = {
    enable = true;
    settings = {
      options.theme = "everforest";
      sections = {
        lualine_c = [
          {
            __raw = ''
              function()
                local ok, mode = pcall(vim.fn["skkeleton#mode"])
                return _G.utils.get_skkeleton_state(ok, mode)
              end
            '';
          }
          {
            __raw = ''
              function()
                return _G.utils.get_autoformat_state()
              end
            '';
          }
        ];
        lualine_x = [ "filename" ];
      };
      inactive_sections = {
        lualine_x = [ "filename" ];
      };
      extensions = [
        "fzf"
        "oil"
        "quickfix"
      ];
    };
  };

  # Neoscroll
  plugins.neoscroll = {
    enable = true;
    settings.mappings = [
      "<C-u>"
      "<C-d>"
    ];
  };

  # tiny-glimmer
  plugins.tiny-glimmer = {
    enable = true;
    autoLoad = true;
  };
}
