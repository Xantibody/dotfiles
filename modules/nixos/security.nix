{
  rtkit.enable = true;
  polkit.enable = true;
  pam = {
    services = {
      login.fprintAuth = true;
      sudo.fprintAuth = true;
    };
  };
}
