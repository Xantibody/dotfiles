{
  rtkit.enable = true;
  polkit.enable = true;
  pam = {
    services = {
      login.fprintAuth = true;
      sudo.fprintAuth = true;
    };
  };

  # pam.services.lightdm.text = ''
  #   auth      sufficient pam_unix.so try_first_pass likeauth nullok
  #   auth      sufficient pam_fprintd.so
  #   auth      required   pam_deny.so
  #   account   required   pam_unix.so
  #   session   required   pam_unix.so
  # '';
}
