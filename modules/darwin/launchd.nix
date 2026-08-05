{
  pkgs,
  username,
  colima,
  ...
}:
{
  user.agents = {
    colima = {
      serviceConfig = {
        Program = "${pkgs.colima}/bin/colima";
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
          "--cpu"
          (toString colima.cpu)
          "--memory"
          (toString colima.memory)
          "--vm-type"
          "vz"
          "--vz-rosetta"
          "--mount-type"
          "virtiofs"
        ];
        # `colima start` は VM を起こして終了する一回きりのコマンドで、常駐しない。
        # KeepAlive を付けると launchd が終了のたびに再実行し、起動に失敗する設定
        # だったときは 11 秒周期の無限ループになる。失敗した試行は usernet デーモンを
        # 孤児として残すので、半日ほどでプロセス上限を食い潰してマシン全体が
        # fork できなくなる (実測 2414 個)。
        KeepAlive = false;
        RunAtLoad = true;
        StandardOutPath = "/tmp/colima.log";
        StandardErrorPath = "/tmp/colima.err";
      };
    };

    yaskkserv2 = {
      serviceConfig = {
        Program = "${pkgs.yaskkserv2}/bin/yaskkserv2";
        ProgramArguments = [
          "${pkgs.yaskkserv2}/bin/yaskkserv2"
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
