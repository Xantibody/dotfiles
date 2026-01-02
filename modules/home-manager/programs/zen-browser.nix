{ pkgs }:
{
  enable = true;
  profiles.r-aizawa = {
    settings = {
      "extensions.autoDisableScopes" = 0;
      "zen.theme.content-element-separation" = 0;
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
