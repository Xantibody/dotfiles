# Zen Browser (Beta)。macOS では署名保持版を /Applications/Nix Apps/ に置く。
#
# 問題1 (署名) は解決済み: かつて zen-browser-flake の installDarwin は公式署名済み
#   .app を改変後に `/usr/bin/codesign --sign -` で ad-hoc 再署名し、Zen 元来の
#   Apple Developer 署名 (Team ID 9V5K9TP787) を剥がしていた。upstream は PR #212 を
#   取り込まず、同等の修正を 17a400c として main に入れており、現在の installDarwin は
#   .app を一切改変しない。よって署名目的の override はもう不要。
#
# 問題2 (配置) は未解決なので、以下の installPhase override が残っている:
#   1Password の native core は署名が正しくても /nix/store 配置のブラウザを検証で
#   拒否する (BrowserVerificationFailed)。このパッケージを environment.systemPackages
#   に入れ、nix-darwin に標準ロケーション /Applications/Nix Apps/ へ署名保持コピー
#   させることで回避する。
#   upstream の launcher は home-manager 前提で
#   `$HOME/Applications/Home Manager Apps/` を見にいくが、ここは systemPackages 経由の
#   配置なのでそのパスは存在せず、/nix/store へフォールバックして 1Password に弾かれる。
#   そのため launcher の STABLE_PATH だけを /Applications/Nix Apps/ に差し替える。
#   (upstream をそのまま使えるようになるのは 1Password が /nix/store を受け付けた場合のみ)
#
# プロファイル/拡張/設定は home-manager の programs.zen-browser が package = null で
# 別途管理する。
#
# Refs: 0xc000022070/zen-browser-flake#82, #212; zen-browser/desktop#10788
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;

  # 署名保持版 (macOS 用)。理由は上のコメント。
  signedOverlay = final: _prev: {
    zen-beta-signed =
      inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs
        (_: {
          installPhase = ''
            runHook preInstall

            mkdir -p "$out/Applications" "$out/bin"
            cp -r *.app "$out/Applications/Zen Browser (Beta).app"

            cat > "$out/bin/zen-beta" << EOF
            #!/bin/bash
            STABLE_PATH="/Applications/Nix Apps/Zen Browser (Beta).app"
            if [[ -e "\$STABLE_PATH" ]]; then
              exec /usr/bin/open -na "\$STABLE_PATH" --args "\$@"
            else
              exec /usr/bin/open -na "$out/Applications/Zen Browser (Beta).app" --args "\$@"
            fi
            EOF

            chmod +x "$out/bin/zen-beta"
            ln -s "$out/bin/zen-beta" "$out/bin/zen"

            runHook postInstall
          '';
          dontFixup = true;
        });
  };
in
{
  flake.modules.homeManager.zen =
    { pkgs, lib, ... }:
    let
      rycee-addons = pkgs.firefox-addons;
      my-nur-addons = inputs.my-nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.firefox-addons;
    in
    {
      imports = [ inputs.zen-browser.homeModules.beta ];

      programs.zen-browser = {
        enable = true;

        # macOS では署名保持版を environment.systemPackages 経由で
        # /Applications/Nix Apps/ へ配置するので、ここでは package を入れず (null)、
        # プロファイル/拡張/設定だけを home-manager で管理する。
        package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;

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
    };

  flake.modules.darwin.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.overlays = [
        signedOverlay
        inputs.firefox-addons.overlays.default
      ];
      environment.systemPackages = [ pkgs.zen-beta-signed ];
      home-manager.sharedModules = [ hm.zen ];

      # 1Password 連携のため /Applications/Nix Apps/ 版 (署名保持コピー) を pin する。
      # Home Manager Apps / trampoline 版は /nix/store 解決 or ad-hoc 署名で 1Password に弾かれる。
      my.dock.apps = lib.mkOrder 100 [ "/Applications/Nix Apps/Zen Browser (Beta).app" ];

      # 既定ブラウザを Zen にする。macOS には宣言的な設定が無いので毎回叩く。
      system.activationScripts.postActivation.text = ''
        sudo -u ${config.my.user.name} ${pkgs.defaultbrowser}/bin/defaultbrowser zen
      '';
    };

  flake.modules.nixos.zen = {
    nixpkgs.overlays = [ inputs.firefox-addons.overlays.default ];
    home-manager.sharedModules = [ hm.zen ];

    # 1Password の native messaging は許可したブラウザ名しか受け付けない
    environment.etc."1password/custom_allowed_browsers" = {
      text = ''
        .zen-wrapped
      ''; # or just "zen" if you use unwrapped package
      mode = "0755";
    };
  };
}
