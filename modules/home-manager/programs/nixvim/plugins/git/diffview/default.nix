# Diffview Git差分ビューア
{ pkgs, ... }:
{
  plugins.diffview = {
    enable = true;
    settings.enhanced_diff_hl = true;
  };

  # Diffview Lua設定（keymaps）を読み込む
  extraFiles."lua/plugins/git/diffview/config.lua".source = ./config.lua;
  extraConfigLua = ''require("plugins.git.diffview.config")'';
}
