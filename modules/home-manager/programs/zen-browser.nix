{ pkgs }:
{
  enable = true;
  profiles.r-aizawa = {
    settings = {
      "extensions.autoDisableScopes" = 0;
    };
    extensions = {
      packages = (
        with pkgs.firefox-addons;
        [
          vimium
          onepassword-password-manager
        ]
      );
    };
  };
}
