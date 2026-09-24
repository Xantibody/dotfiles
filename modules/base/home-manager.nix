# home-manager を system 構成の中に載せる配線。
# 機能側は flake.modules.homeManager.<name> を書き、自分の darwin / nixos module から
# home-manager.sharedModules に足す。ホストは機能名を 1 回挙げるだけで済む。
{ inputs, ... }:
let
  common =
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        extraSpecialArgs = { inherit inputs; };
        # 管理外の既存ファイルは activation を止めずに退避させる。home.file の配り方を
        # 変えた世代 (recursive な tree → dir ごとの symlink など) を、しばらく switch して
        # いなかったホストに当てると必ず衝突するので、darwin / nixos の両方に効かせる。
        # AIDEV-NOTE: force = true は採らない。衝突に気付けず、退避された .backup も残らない
        backupFileExtension = "backup";
        users.${config.my.user.name}.home = {
          username = config.my.user.name;
          homeDirectory = config.my.user.home;
          stateVersion = "24.11";
          sessionPath = [ "$HOME/.local/bin" ];
        };
      };
    };
in
{
  flake.modules.darwin.home-manager = {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      common
    ];
  };

  flake.modules.nixos.home-manager = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      common
    ];
  };
}
