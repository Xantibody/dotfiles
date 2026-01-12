{
  pkgs,
  inputs,
  ...
}:
let
  rycee-addons = pkgs.firefox-addons;
  my-nur-addons = inputs.my-nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox-addons;
in
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
        packages = [
          rycee-addons.keepa
          rycee-addons.onepassword-password-manager
          rycee-addons.vimium
          rycee-addons.wayback-machine
          my-nur-addons.plamo-translate
        ];
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
