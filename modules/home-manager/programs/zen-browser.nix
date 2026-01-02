{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.zen-browser.homeModules.beta ];
  programs.zen-browser = {
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

      search = {
        force = true;
        engines = {
          nix-packages = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
        };
      };

    };
  };
}
