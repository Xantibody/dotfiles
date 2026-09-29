# felis: セッションがウィンドウより長生きする GPU ターミナル (git.natsukium.com/natsukium/felis)。
# NixOS だけに入れる。darwin は kitty のまま。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.felis =
    { pkgs, ... }:
    {
      imports = [ inputs.felis.homeManagerModules.felis ];

      programs.felis = {
        enable = true;
        # 上流 module の既定はこちらの nixpkgs で組み直すので、下のキャッシュに当たらない。
        # flake.nix で nixpkgs を follows させていないのも同じ理由
        package = inputs.felis.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
          font = {
            family = "Explex Console NF";
            # kitty の 11pt に揃える (px = pt * 4/3)
            size_px = 11 * 4.0 / 3.0;
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

        # 窓を閉じて裏に回したセッションの OSC 9 / 99 / 777 を mako に流す
        notifications.enable = true;
      };
    };

  flake.modules.nixos.felis = {
    nix.settings = {
      extra-substituters = [ "https://nix-cache.natsukium.com" ];
      extra-trusted-public-keys = [ "niks3-1:SoIFTPtiPoCW3/OzUkIBKlLG5znMZfbihlr11XAOles=" ];
    };

    home-manager.sharedModules = [ hm.felis ];
  };
}
