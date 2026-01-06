# Lualine ステータスライン
{
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
}
