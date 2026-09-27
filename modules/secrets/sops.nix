# sops-nix。実際に復号しているのは work host の gitconfig だけ (modules/git/work.nix)。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.sops = inputs.sops-nix.homeManagerModules.sops;

  flake.modules.darwin.sops = {
    home-manager.sharedModules = [ hm.sops ];
  };

  # 復号は home-manager 側だけなので、NixOS の sops module は載せない
  flake.modules.nixos.sops = {
    home-manager.sharedModules = [ hm.sops ];
  };
}
