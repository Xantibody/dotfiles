# 私物の MacBook Pro (M3)。
{ config, lib, ... }:
let
  darwin = config.flake.modules.darwin;
in
{
  my.hosts.darwin = [ "private-macbook-pro-m3" ];

  flake.modules.darwin.private-macbook-pro-m3 = {
    # with ではなく attrVals を使う。with の束縛は let や関数引数に負けるので、
    # 同名の名前が入ると黙って別のものを指す。attrVals なら typo はその場で落ちる。
    imports = lib.attrVals [
      "user"
      "nixpkgs"
      "home-manager"
      "spotlight"
      "comma"
      "neovim"
      "zen"
      "magical-merchant"
      "legacy"
    ] darwin;

    my.user = {
      name = "ryu.aizawa";
      home = "/Users/ryu.aizawa";
    };
    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
