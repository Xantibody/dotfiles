{ pkgs, ... }:
{
  shells = [ pkgs.fish ];
  systemPackages = with pkgs; [
    # _1password-gui  # 1Password は Homebrew cask を手動導入したため一旦コメントアウト
    # brewCasks.claude  # Claude は Homebrew cask を手動導入したため一旦コメントアウト
    google-chrome
  ];
}
