{ pkgs, ... }:
{
  shells = [ pkgs.fish ];
  systemPackages = [
    pkgs.colima
    pkgs.lima-additional-guestagents
    pkgs.docker
    pkgs.docker-compose
    pkgs.docker-buildx
  ];
}
