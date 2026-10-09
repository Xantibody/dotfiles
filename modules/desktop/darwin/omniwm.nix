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
  flake.modules.homeManager.omniwm =
    { lib, ... }:
    {
      programs.omniwm = {
        enable = true;
        settings = ../../../configs/omniwm/settings.toml;
        # 終了させたら終了したままにする。既定の KeepAlive だと launchd が起こし直す
        launchd.keepAlive = false;
      };

      # openCommandPalette の Control+Option+Space は macOS の「入力メニューで
      # 次のソースを選択」(symbolic hotkey 61) と同じキー。入力の切り替えは
      # macSKK の Ctrl+J で足りるので、macOS 側を無効にする。
      # AIDEV-NOTE: targets.darwin.defaults / CustomUserPreferences は
      # AppleSymbolicHotKeys の辞書を丸ごと書き換え、GUI で有効にした他の
      # ショートカット (Ctrl+数字のデスクトップ切り替えなど) を消してしまう。
      # だから 61 だけを -dict-add で足す
      home.activation.disableInputSourceHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 \
          '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>786432</integer></array><key>type</key><string>standard</string></dict></dict>'
        run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
    };

  flake.modules.darwin.omniwm = {
    home-manager.sharedModules = [ hm.omniwm ];

    # 操作スペースを使用頻度で並べ替えられると、OmniWM のワークスペースと順番がずれる
    system.defaults.dock.mru-spaces = false;
  };
}
