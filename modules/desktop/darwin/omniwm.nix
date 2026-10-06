# OmniWM (niri / Hyprland 風のタイル型 WM)。macOS で Linux の窓の扱いに寄せる。
# 本体だけを入れ、settings.toml (~/.config/omniwm) は GUI に任せる。
# AIDEV-NOTE: settings.toml を home-manager で store に固めると GUI からの保存が通らない。
# 既定のまま慣らし、落ち着いてから取り込むか決める
{
  flake.modules.darwin.omniwm =
    { pkgs, ... }:
    {
      # nixpkgs 版は上流の署名済み .app をそのまま置くので、更新しても TCC の許可が残る
      environment.systemPackages = [ pkgs.omniwm ];

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
