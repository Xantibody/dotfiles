# felis: セッションがウィンドウより長生きする GPU ターミナル (git.natsukium.com/natsukium/felis)。
# Linux では Hyprland / niri、macOS では OmniWM が窓を並べる前提で、split も tab も持たない felis をそのまま使う。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;

  # 上流が自分の lock で組んだものを置いているキャッシュ
  cache = {
    extra-substituters = [ "https://nix-cache.natsukium.com" ];
    extra-trusted-public-keys = [ "niks3-1:SoIFTPtiPoCW3/OzUkIBKlLG5znMZfbihlr11XAOles=" ];
  };
in
{
  flake.modules.homeManager.felis =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.felis.homeManagerModules.felis ];

      programs.felis = {
        enable = true;
        # 上流 module の既定はこちらの nixpkgs で組み直すので、下のキャッシュに当たらない。
        # flake.nix で nixpkgs を follows させていないのも同じ理由
        # darwin module が再署名したものに差し替えるので mkDefault
        package = lib.mkDefault inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
          font = {
            family = "Explex Console NF";
            # kitty の 11pt に揃える。Linux は 96dpi で px = pt * 4/3、macOS は 1pt が 1 論理 px
            size_px = if pkgs.stdenv.hostPlatform.isDarwin then 11.0 else 11 * 4.0 / 3.0;
          };

          # dayfox。kitty.nix と同じ値。selection と url の色を持つ key は felis にない
          theme = {
            background = "#f6f2ee";
            foreground = "#3d2b5a";
            palette = {
              black = "#352c24";
              red = "#a5222f";
              green = "#396847";
              yellow = "#ac5402";
              blue = "#2848a9";
              magenta = "#6e33ce";
              cyan = "#287980";
              white = "#f2e9e1";
              bright_black = "#534c45";
              bright_red = "#b3434e";
              bright_green = "#577f63";
              bright_yellow = "#b86e28";
              bright_blue = "#4863b6";
              bright_magenta = "#8452d5";
              bright_cyan = "#488d93";
              bright_white = "#f4ece6";
              indexed = {
                "16" = "#955f61";
                "17" = "#a440b5";
              };
            };
          };
          cursor.color = "#3d2b5a";

          # kitty の hide_window_decorations = titlebar-only に当たる
          window.decorations = false;

          # felis に split も tab もない。kitty のタブに当たるのはセッションで、
          # タブ操作の chord (kitty の既定と kitty.nix の上書き) をセッション操作に当てる。
          # split の ctrl+shift+\ と ctrl+shift+- は当てる先がないので、
          # ctrl+shift+- は felis 既定の文字縮小のまま
          keymap = {
            "ctrl+shift+t" = {
              kind = "new_session";
            };
            "ctrl+shift+enter" = {
              kind = "new_session";
            };
            "ctrl+shift+right" = {
              kind = "switch_session";
              to = "next";
            };
            "ctrl+shift+left" = {
              kind = "switch_session";
              to = "previous";
            };
            # 確認バーを挟んでから殺す。窓を閉じるだけならセッションは残る
            "ctrl+shift+w" = {
              kind = "kill_session";
            };
            "ctrl+shift+q" = {
              kind = "kill_session";
            };
            "ctrl+shift+h" = {
              kind = "pipe";
              source = "scrollback";
              ansi = true;
            };
            # kitty の hints (open_url) に当たる。felis は URL を自分で探さないので、
            # 見えている範囲を urlscan に渡して選ばせる
            "ctrl+shift+e" = {
              kind = "pipe";
              source = "visible";
              target.command = [
                "${pkgs.urlscan}/bin/urlscan"
                "--compact"
                "--dedupe"
                "--single"
              ];
            };
            "ctrl+shift+backspace" = {
              kind = "font_size";
              step = "reset";
            };
            "ctrl+shift+f5" = {
              kind = "reload";
            };
            "ctrl+shift+f11" = {
              kind = "toggle_fullscreen";
            };
          };
        };

        # 窓を閉じて裏に回したセッションの OSC 9 / 99 / 777 を通知に流す (Linux は mako、macOS は通知センター)
        notifications.enable = true;
      };

      # 下の 2 本は waybar と rofi が前提なので Linux だけに置く。
      # waybar の custom/felis が呼ぶ。セッションを前面のプロセス名で並べ、窓の付いていない
      # ものは薄くする。tooltip には id とタイトルを出す。
      # AIDEV-NOTE: フォーカス中の窓のセッションは出さない。attachment に窓の pid が無く、
      # Hyprland のタイトルとの突き合わせでは同じ "~" の fish を区別できない
      home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
        (pkgs.writeShellApplication {
          name = "felis-waybar";
          runtimeInputs = [
            config.programs.felis.package
            pkgs.jq
          ];
          text = ''
            # daemon が居なければ空を返し、waybar にモジュールを隠させる
            if ! sessions=$(felis sessions list --format json 2>/dev/null); then
              echo '{"text":""}'
              exit 0
            fi
            jq -c '
              def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
              .sessions
              | map(. + { fg: (.foreground // "?" | esc), detached: (.attachments | length == 0) })
              | {
                  text: map(if .detached then "<span alpha=\"45%\">\(.fg)</span>" else .fg end) | join("  "),
                  tooltip: map("\(if .detached then "○" else "●" end) \(.short_id)  \(.fg)  \(.title | esc)") | join("\n")
                }
            ' <<<"$sessions"
          '';
        })

        # waybar の custom/felis のクリックから開くメニュー。
        #   felis-menu attach: 選んだセッションに窓を 1 枚足す (付いている窓はそのまま残る)
        #   felis-menu manage: 選んだセッションの窓を全部外すか、セッションごと消す
        # 見た目は waybar の Bluetooth メニューの rasi を借り、見出しと幅だけ差し替える
        (pkgs.writeShellApplication {
          name = "felis-menu";
          runtimeInputs = [
            config.programs.felis.package
            pkgs.jq
          ];
          text = ''
            menu() {
              rofi -dmenu -i -p "" -config "$HOME/.config/rofi/bluetooth-menu.rasi" \
                -theme-str "textbox-custom { content: \"felis\"; } window { width: 480px; }"
            }

            # 1 行 1 セッション。2 列目の short_id を選択結果から切り出す
            pick() {
              felis sessions list --format json \
                | jq -r '.sessions[] | "\(if (.attachments | length) == 0 then "○" else "●" end) \(.short_id)  \(.foreground // "?")  \(.title)"' \
                | menu | awk '{ print $2 }'
            }

            case "''${1:-}" in
              attach)
                id=$(pick)
                [ -n "$id" ] || exit 0
                exec felis attach "$id"
                ;;
              manage)
                id=$(pick)
                [ -n "$id" ] || exit 0
                case "$(printf 'Evict windows\nKill session\n' | menu)" in
                  "Evict windows") felis sessions evict "$id" ;;
                  "Kill session") felis sessions kill "$id" ;;
                esac
                ;;
              *)
                echo "usage: felis-menu attach|manage" >&2
                exit 2
                ;;
            esac
          '';
        })
      ];
    };

  flake.modules.nixos.felis = {
    nix.settings = cache;

    home-manager.sharedModules = [ hm.felis ];
  };

  flake.modules.darwin.felis =
    { pkgs, ... }:
    let
      # 素の ad-hoc 署名だと、アクセシビリティ等の許可が rebuild のたびに飛ぶ。
      # hm の programs.felis と skhd の起動パスが同じ .app を指すよう、ここで一度だけ作る
      felis =
        (pkgs.callPackage inputs.nix-mac-app-identity { }).stabilizeApp
          inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      nix.settings = cache;

      home-manager.sharedModules = [
        hm.felis
        { programs.felis.package = felis; }
      ];

      # Hyprland の $mod+Q に当たる。OmniWM はアプリの起動をホットキーに持てないので skhd に任せる。
      # Hyper (ctrl+alt+shift+cmd) は左 Control を OmniWM の Hyper トリガーにして押す。
      # トリガーで作った Hyper は skhd にも 4 修飾として届くので Karabiner は要らない。
      # cmd+q はどのアプリでも終了なので奪わない。
      # felis は起動元の $SHELL を開く。macOS のログインシェルは zsh のままなので、
      # kitty の shell と同じ fish を渡す
      # AIDEV-NOTE: chsh で fish に変えないのは会社の Mac が Kandji 管理だから。
      # users.users.shell は knownUsers に入れないと効かず、入れると nix-darwin がユーザを管理しだす
      services.skhd = {
        enable = true;
        skhdConfig = ''
          ctrl + alt + shift + cmd - q : /usr/bin/open -na ${felis}/Applications/felis.app --env SHELL=${pkgs.fish}/bin/fish
        '';
      };
    };
}
