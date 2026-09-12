# `, <コマンド名>` で入れていないコマンドをその場だけ実行する。
# nix-index のデータベースは自前で作ると数十分かかるので、事前ビルド済みのものを引く。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.comma ];
  };
in
{
  flake.modules.homeManager.comma = {
    imports = [ inputs.nix-index-database.homeModules.default ];
    programs.nix-index-database.comma.enable = true;
  };

  flake.modules.darwin.comma = share;
  flake.modules.nixos.comma = share;
}
