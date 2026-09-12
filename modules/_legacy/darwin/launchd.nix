{
  pkgs,
  username,
  ...
}:
{
  user.agents = {
    yaskkserv2 = {
      serviceConfig = {
        Program = "${pkgs.yaskkserv2}/bin/yaskkserv2";
        ProgramArguments = [
          "${pkgs.yaskkserv2}/bin/yaskkserv2"
          # 既定では fork して親が exit 0 するため、KeepAlive の launchd が
          # 「終了した」と見なして 10 秒ごとに再スポーンし、新しい方は
          # ポート 1178 が使用中で即終了する無限ループになる (実測 82 回/5 分)。
          "--no-daemonize"
          "/Users/${username}/.skk/dictionary.yaskkserv2"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/yaskkserv2.log";
        StandardErrorPath = "/tmp/yaskkserv2.err";
      };
    };
    maccy = {
      serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "Maccy"
        ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };
}
