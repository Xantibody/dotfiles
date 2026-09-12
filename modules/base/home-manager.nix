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
        users.${config.my.user.name}.home = {
          username = config.my.user.name;
          homeDirectory = config.my.user.home;
          stateVersion = "24.11";
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
    home-manager.backupFileExtension = "backup";
  };
}
