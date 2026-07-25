{ pkgs, ... }:
{
  shells = [ pkgs.fish ];
  systemPackages = with pkgs; [
    # _1password-gui  # 1Password は Homebrew cask を手動導入したため一旦コメントアウト
    colima
    docker
    docker-buildx
    docker-compose
    lima-additional-guestagents
    brewCasks.maccy
    # brewCasks.claude  # Claude は Homebrew cask を手動導入したため一旦コメントアウト
    google-chrome
  ];
}
