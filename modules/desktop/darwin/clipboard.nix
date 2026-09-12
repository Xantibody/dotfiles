# Maccy (クリップボード履歴)。Homebrew cask をそのまま入れ、ログイン時に起動する。
{ config, ... }:
{
  flake.modules.darwin.clipboard =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.brewCasks.maccy ];
      launchd.user.agents.maccy.serviceConfig = {
        ProgramArguments = [
          "/usr/bin/open"
          "-a"
          "Maccy"
        ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
}
