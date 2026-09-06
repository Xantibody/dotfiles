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
