# mdsf は markdown のコードブロックを言語ごとのフォーマッタにかける。
# 設定は JSON を読んで store へ書き直すだけ (スキーマ検証を pkgs.formats に任せる)。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.mdsf ];
  };
in
{
  flake.modules.homeManager.mdsf =
    { pkgs, ... }:
    let
      jsonFormat = pkgs.formats.json { };
      mdsfConfig = builtins.fromJSON (builtins.readFile ./mdsf.json);
    in
    {
      home.file.".mdsf.json".source = jsonFormat.generate "mdsf.json" mdsfConfig;
    };

  flake.modules.darwin.mdsf = share;
  flake.modules.nixos.mdsf = share;
}
