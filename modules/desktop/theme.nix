# デスクトップの配色。Stylix が base16 の 1 スキームを各アプリに配る。
#
# 層は 3 つで、下ほど優先される:
#   1. 配色: nixpkgs の base16-schemes (tinted-theming)。nixpkgs を上げれば上流に追従する
#   2. 色の上書き: stylix.override = { base0D = "..."; }; を足す (今は無し)
#   3. 見た目: waybar と rofi の独自メニューは自前の CSS / rasi のまま、色だけ受け取る
#      (modules/desktop/hyprland/{waybar,rofi}.nix が config.lib.stylix.colors を読む)
#
# kitty・Neovim・fish は dayfox (明るい配色) で揃えているので Stylix に触らせない。
# そのため autoEnable を切り、配る先をここで列挙する。
{ config, inputs, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.theme = {
    stylix.targets = {
      hyprland.enable = true;
      hyprlock.enable = true;
      mako.enable = true;
      rofi.enable = true;
    };
  };

  flake.modules.nixos.theme =
    { config, pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
        polarity = "dark";
        autoEnable = false;
        # 配る先のフォントを、ほかの場所と同じ Explex に寄せる
        fonts = {
          monospace = {
            package = pkgs.explex-nf;
            name = "Explex Console NF";
          };
          sansSerif = config.stylix.fonts.monospace;
          serif = config.stylix.fonts.monospace;
        };
      };

      home-manager.sharedModules = [ hm.theme ];
    };
}
