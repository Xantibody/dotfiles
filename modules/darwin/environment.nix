{ pkgs, ... }:
{
  shells = [ pkgs.fish ];
  systemPackages = with pkgs; [
    colima
    lima-additional-guestagents
    docker
    docker-compose
    docker-buildx
    brewCasks.maccy
    macskk
  ];
}
