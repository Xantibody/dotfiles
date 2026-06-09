{
  pkgs,
  inputs,
  lib,
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

    # macOS では署名保持版 Zen を environment.systemPackages 経由で
    # /Applications/Nix Apps/ へ配置する (modules/darwin/zen-beta-signed.nix)。
    # 1Password の native core が /nix/store 配置を拒否するため、ここでは
    # package を入れず (null)、プロファイル/拡張/設定のみ home-manager で管理する。
    package = lib.mkIf pkgs.stdenv.isDarwin null;

    profiles.r-aizawa = {
      settings = {
        "extensions.autoDisableScopes" = 0;
        "zen.theme.content-element-separation" = 0;
        "browser.translations.enable" = false;
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
