# ランチャ。Hyprland の $menu と、クリップボード履歴の選択に使う。
# ランチャ本体の配色は Stylix の rofi target が、waybar から開く Wi-Fi・Bluetooth・電源の
# メニュー (configs/rofi/*.rasi) の配色は下の theme.rasi が、同じスキームから作る。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.rofi =
    { config, ... }:
    let
      c = config.lib.stylix.colors.withHashtag;
    in
    {
      programs.rofi.enable = true;
      home.file.".config/rofi" = {
        source = ../../../configs/rofi;
        recursive = true;
      };
      # 各メニューが @theme で読む役割名に base16 の色を割り当てる
      xdg.configFile."rofi/theme.rasi".text = ''
        * {
          main-bg:   ${c.base00};
          main-fg:   ${c.base07};
          main-br:   ${c.base0A};
          input-bg:  ${c.base01};
          select-bg: ${c.base0A};
          select-fg: ${c.base00};
        }
      '';
    };

  flake.modules.nixos.rofi = {
    home-manager.sharedModules = [ hm.rofi ];
  };
}
