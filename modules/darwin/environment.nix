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
    brewCasks.claude
    brewCasks.chatgpt
    brewCasks.google-chrome
    macskk
  ];
}
