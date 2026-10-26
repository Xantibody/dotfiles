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

      # 新しいプロファイル切り替えメニューは profiles.ini ではなく
      # Profile Groups/<storeId>.sqlite を見る。全プロファイルを同じグループに入れる
      storeId = "d0f11e5a";
      root = "${config.home.homeDirectory}/${config.programs.firefox.configPath}";
      # home-manager の profiles.ini と同じく、macOS だけ Profiles/ の下に置かれる
      pathOf = name: if pkgs.stdenv.hostPlatform.isDarwin then "Profiles/${name}" else name;

      # 色とアイコンは Firefox の画面で選び直す。登録済みの行は上書きしない
      manifest = pkgs.writeText "firefox-profile-group.json" (
        builtins.toJSON (
          map (name: {
            inherit name;
            path = pathOf name;
            avatar = if name == "private" then "star" else "briefcase";
          }) names
        )
      );
      profileGroup = pkgs.callPackage ./_firefox-profile-group/package.nix { };

      # どのプロファイルも同じ拡張と設定から始める。ホスト固有の拡張は
      # programs.firefox.profiles.<name>.extensions.packages に足せば結合される
      base = {
        # storeId オプションは使わない。古い profiles.ini の 1 エントリに 1 つという
        # 前提で重複を弾くが、新しい仕組みでは同じグループの全員が同じ値を持つ
        settings = {
          "toolkit.profiles.storeID" = storeId;
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
        # HACK(https://github.com/nix-community/home-manager/pull/10073): home-manager は
        # 古い仕組みの profiles.ini しか書かないので、新しい仕組みの登録を自前でやる。
        # Firefox は起動中に profiles.ini の Path を書き換えるので、/nix/store への
        # symlink ではなく普通のファイルとして置く
        home.file."${config.programs.firefox.configPath}/profiles.ini".enable = lib.mkForce false;

        home.activation.firefoxProfileGroup = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${lib.getExe profileGroup} ${
            lib.escapeShellArgs [
              root
              storeId
              "${manifest}"
            ]
          }
        '';

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
