# 画面上端のステータスバー。設定は configs/waybar/ にある jsonc と css。
# 色は Stylix (modules/desktop/theme.nix) のスキームから作るので、theme を載せるホストでしか使えない。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.waybar =
    { config, lib, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;

      # style.css が参照する役割名に base16 の色を割り当てる。見た目の調整はここではなく style.css で
      palette = ''
        @define-color main-bg         ${c.base00};
        @define-color main-fg         ${c.base05};
        @define-color main-br         ${c.base05};
        @define-color shadow          shade(${c.base00}, 0.5);

        @define-color active-bg       ${c.base0A};
        @define-color active-fg       ${c.base00};
        @define-color hover-bg        ${c.base02};
        @define-color hover-fg        alpha(${c.base05}, 0.75);

        /* モジュールの背景は base00 から base02 へ向かう階段。1 段目は base00 と base01 の間 */
        @define-color step1           mix(${c.base00}, ${c.base01}, 0.3);
        @define-color module-fg       ${c.base05};
        @define-color workspaces      @step1;
        @define-color temperature     @step1;
        @define-color memory          ${c.base01};
        @define-color cpu             ${c.base02};
        @define-color distro-fg       ${c.base00};
        @define-color distro-bg       ${c.base0A};
        @define-color time            ${c.base02};
        @define-color date            ${c.base01};
        @define-color tray            @step1;
        @define-color pulseaudio      @step1;
        @define-color backlight       ${c.base01};
        @define-color battery         ${c.base02};
        @define-color power           ${c.base0A};

        @define-color warning         ${c.base09};
        @define-color critical        ${c.base08};
        @define-color charging        ${c.base0B};
      '';

      # config.jsonc の pango markup は CSS の変数を読めないので、Gruvbox の色を直書きしたまま
      # 置き、ここで同じ役割の base16 色に差し替える
      recolor = lib.replaceStrings (lib.attrNames gruvbox) (lib.attrValues gruvbox);
      gruvbox = {
        "#458588" = c.base0D;
        "#98971a" = c.base0B;
        "#cc241d" = c.base08;
        "#d65d0e" = c.base09;
        "#b16286" = c.base0E;
        "#d5c4a1" = c.base05;
        "#928374" = c.base04;
      };
    in
    {
      programs.waybar = {
        enable = true;
        # exec-once で起動すると、pipewire-pulse より先に立ち上がった回に pulseaudio
        # モジュールが接続失敗の例外で abort し、バーが消えたままになる。systemd なら
        # セッションの準備を待ち、落ちても再起動される
        systemd.enable = true;
      };

      home.file.".config/waybar" = {
        source = builtins.path {
          name = "waybar";
          path = ../../../configs/waybar;
          filter = path: _: baseNameOf path != "config.jsonc";
        };
        recursive = true;
      };
      xdg.configFile = {
        "waybar/config.jsonc".text = recolor (builtins.readFile ../../../configs/waybar/config.jsonc);
        "waybar/theme.css".text = palette;
      };
    };

  flake.modules.nixos.waybar = {
    home-manager.sharedModules = [ hm.waybar ];
  };
}
