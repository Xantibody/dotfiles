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

  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
    home-manager.sharedModules = [ hm.sops ];
  };
}
