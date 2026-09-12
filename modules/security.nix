# 特権昇格まわり。ログイン時の認証は hardware/e14gen6/fingerprint.nix 側。
{
  flake.modules.nixos.security = {
    security.polkit.enable = true;
    security.pam.services.hyprlock = { };
  };
}
