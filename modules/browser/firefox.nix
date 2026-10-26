# Firefox。macOS では Mozilla 署名のままの firefox-bin を /Applications/Nix Apps/ に置く。
#
# 1Password の native core は /nix/store 配置のブラウザを検証で拒否するので
# (zen.nix の問題2 と同じ)、environment.systemPackages に入れて nix-darwin に
# /Applications/Nix Apps/ へコピーさせる。firefox-bin-unwrapped は dmg の .app を
# mv するだけで dontFixup なので署名は残る。wrap 版 (firefox-bin) は使わない。
#
# プロファイル/拡張/設定は home-manager の programs.firefox が macOS では
# package = null で別途管理する。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  app = "/Applications/Nix Apps/Firefox.app";
in
{
  flake.modules.homeManager.firefox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      rycee-addons = pkgs.firefox-addons;
      my-nur-addons = inputs.my-nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox-addons;

      names = [ "private" ] ++ config.my.firefox.profiles;

      # どのプロファイルも同じ拡張と設定から始める。ホスト固有の拡張は
      # programs.firefox.profiles.<name>.extensions.packages に足せば結合される
      base = {
        settings = {
          "extensions.autoDisableScopes" = 0;
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
    in
    {
      options.my.firefox.profiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "全ホスト共通の private に加えて作るプロファイル。仕事先ごとに分ける";
      };

      config = {
        programs.firefox = {
          enable = true;

          # macOS では systemPackages 経由で /Applications/Nix Apps/ へ置くので入れない
          package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;

          # 先頭の private が id 0 で既定になる
          profiles = lib.listToAttrs (
            lib.imap0 (
              id: name:
              lib.nameValuePair name (
                base
                // {
                  inherit id;
                  isDefault = id == 0;
                }
              )
            ) names
          );
        };
      };
    };

  flake.modules.darwin.firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # keepa が unfree なので、flake の packages ではなく allowUnfree な pkgs に載せる
      nixpkgs.overlays = [ inputs.firefox-addons.overlays.default ];
      environment.systemPackages = [ pkgs.firefox-bin-unwrapped ];
      home-manager.sharedModules = [ hm.firefox ];

      # 1Password 連携のため /Applications/Nix Apps/ 版を pin する
      my.dock.apps = lib.mkOrder 100 [ app ];

      # Hyprland の $mod+F に当たる。unwrapped には bin が無いので .app を直接開く
      services.skhd.skhdConfig = ''
        ctrl + alt + shift + cmd - f : /usr/bin/open -a "${app}"
      '';

      # 既定ブラウザを Firefox にする。macOS には宣言的な設定が無いので毎回叩く。
      system.activationScripts.postActivation.text = ''
        sudo -u ${config.my.user.name} ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
      '';
    };

  flake.modules.nixos.firefox = {
    nixpkgs.overlays = [ inputs.firefox-addons.overlays.default ];
    home-manager.sharedModules = [ hm.firefox ];

    # 1Password の native messaging は許可したブラウザ名しか受け付けない。
    # nixpkgs の firefox は .firefox-wrapped を経由するので両方並べる
    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        .firefox-wrapped
        firefox
      '';
      mode = "0755";
    };
  };
}
