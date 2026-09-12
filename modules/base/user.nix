# このホストを使う人。名前とホームディレクトリは darwin / nixos / home-manager の
# 3 箇所から要るので、host が 1 度だけ書いて option 経由で配る。
# specialArgs で引き回すのをやめたのは、値の出どころが型で分かるようにするため。
{ lib, ... }:
let
  declaration = {
    options.my.user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "ログインユーザ名";
      };
      home = lib.mkOption {
        type = lib.types.str;
        description = "ホームディレクトリ。macOS と Linux で親が違うので host が決める";
      };
    };
  };
in
{
  flake.modules.darwin.user =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ declaration ];

      users.users.${config.my.user.name} = {
        name = config.my.user.name;
        home = config.my.user.home;
        shell = pkgs.fish;
      };
      system.primaryUser = config.my.user.name;
    };

  flake.modules.nixos.user =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ declaration ];

      users.users.${config.my.user.name} = {
        isNormalUser = true;
        description = "r-aizawa";
        home = config.my.user.home;
        shell = pkgs.fish;
        # 所属グループはユーザの性質なので、docker や networkmanager を
        # 有効にするファイル側ではなくここに置く (並び順を固定したい理由もある)
        extraGroups = [
          "docker"
          "networkmanager"
          "wheel"
        ];
        packages = [ ];
      };
    };
}
