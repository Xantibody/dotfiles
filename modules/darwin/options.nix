{ pkgs, ... }:
{
  launchd.user.agents.colima = {
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
}
