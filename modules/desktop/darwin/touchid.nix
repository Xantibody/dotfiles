# sudo を Touch ID で通す。
{
  flake.modules.darwin.touchid = {
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
