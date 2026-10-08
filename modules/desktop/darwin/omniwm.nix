# OmniWM (niri / Hyprland 風のタイル型 WM)。macOS で Linux の窓の扱いに寄せる。
# 設定は configs/omniwm/settings.toml。Hyprland の $mod+C (killactive) に当たる
# Hyper+C は、そこで closeFocusedWindow に割り当てている。
# AIDEV-NOTE: settings.toml は store への symlink なので、GUI から変えた設定は保存されない。
# GUI で試した値は configs/omniwm/settings.toml に書き戻す。OmniWM はファイルを監視して
# 読み直すので、rebuild すれば再起動なしで効く。force は、GUI の保存が symlink を
# 実ファイルに置き換えていても rebuild で戻すため
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.omniwm = {
    xdg.configFile."omniwm/settings.toml" = {
      source = ../../../configs/omniwm/settings.toml;
      force = true;
    };
  };

  flake.modules.darwin.omniwm =
    { pkgs, ... }:
    {
      # nixpkgs 版は上流の署名済み .app をそのまま置くので、更新しても TCC の許可が残る
      environment.systemPackages = [ pkgs.omniwm ];

      home-manager.sharedModules = [ hm.omniwm ];

      launchd.user.agents.omniwm.serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "OmniWM"
        ];
        RunAtLoad = true;
        KeepAlive = false;
      };

      # 操作スペースを使用頻度で並べ替えられると、OmniWM のワークスペースと順番がずれる
      system.defaults.dock.mru-spaces = false;
    };
}
