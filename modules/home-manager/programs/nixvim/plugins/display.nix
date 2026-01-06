# 表示系プラグイン: alpha, flash, hlslens, lualine, neoscroll, nightfox, render-markdown
{ pkgs, ... }:
{
  # Alpha (dashboard)
  # extraPlugins + extraConfigLuaで設定（NixVimのalphaはconfigを上書きするため無効）

  # tiny-glimmer
  plugins.tiny-glimmer = {
    enable = true;
    autoLoad = true;
  };
}
