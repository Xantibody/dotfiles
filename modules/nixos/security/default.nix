{
  rtkit = import ./rtkit.nix;
  polkit = import ./polkit.nix;
  pam = import ./pam.nix;
} // import ./polkit-rules.nix