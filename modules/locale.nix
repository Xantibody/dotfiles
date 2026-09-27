# 言語とタイムゾーン。LC_* は defaultLocale がそのまま効く。
{
  flake.modules.nixos.locale = {
    time.timeZone = "Asia/Tokyo";
    i18n.defaultLocale = "ja_JP.UTF-8";
  };
}
