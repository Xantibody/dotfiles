{ pkgs, username, ... }:
{
  user.agents = {
    colima = {
      serviceConfig = {
        Program = "${pkgs.colima}/bin/colima";
        ProgramArguments = [
          "${pkgs.colima}/bin/colima"
          "start"
          "--cpu"
          "11"
          "--memory"
          "24"
          "--vm-type"
          "vz"
          "--vz-rosetta"
          "--mount-type"
          "virtiofs"
        ];
        KeepAlive = true;
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
