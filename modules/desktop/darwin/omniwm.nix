# OmniWM (niri / Hyprland 風のタイル型 WM)。macOS で Linux の窓の扱いに寄せる。
# 設定は configs/omniwm/settings.toml。Hyprland の $mod+C (killactive) に当たる
# Hyper+C は、そこで closeFocusedWindow に割り当てている。
# AIDEV-NOTE: settings は home-manager の programs.omniwm に TOML のパスで渡す。
# 公式の install ガイドどおり、repo の TOML が正。OmniWM は store への symlink を
# 保ったままにするので GUI からは保存できず、GUI で試した値はこの TOML に書き戻す。
# 差分だけを attrset で書かないのは、schema 4 は必須キーが 1 つでも欠けると
# ファイルごと無効になるため (settings reference)。OmniWM はファイルを監視して
# 読み直すので、rebuild すれば再起動なしで効く
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.omniwm = {
    programs.omniwm = {
      enable = true;
      settings = ../../../configs/omniwm/settings.toml;
      # 終了させたら終了したままにする。既定の KeepAlive だと launchd が起こし直す
      launchd.keepAlive = false;
    };
  };

  flake.modules.darwin.omniwm = {
    home-manager.sharedModules = [ hm.omniwm ];

    # 操作スペースを使用頻度で並べ替えられると、OmniWM のワークスペースと順番がずれる
    system.defaults.dock.mru-spaces = false;
  };
}
