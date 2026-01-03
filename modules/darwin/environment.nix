{ pkgs, ... }:
{
  shells = [ pkgs.fish ];
  systemPackages = with pkgs; [
    _1password-gui
    colima
    docker
    docker-buildx
    docker-compose
    lima-additional-guestagents
    brewCasks.maccy
    meetingbar
    macskk
  ];
}
