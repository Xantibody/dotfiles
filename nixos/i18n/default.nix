{ pkgs, ... }:
{
  defaultLocale = "ja_JP.UTF-8";
  extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };
  # inputMethod = {
  # enabled = "fcitx5";
  # # fcitx5.addons = with pkgs; [
  #   fcitx5-skk
  #   fcitx5-gtk
  #   libsForQt5.fcitx5-qt
  # ];
  #};
}
