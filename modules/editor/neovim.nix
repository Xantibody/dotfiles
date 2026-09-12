# nixCats で組む neovim。設定の実体はまだ modules/_legacy/ 側にある。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.neovim ];
  };
in
{
  flake.modules.homeManager.neovim = ../_legacy/home-manager/programs/nixcats;

  flake.modules.darwin.neovim = share;
  flake.modules.nixos.neovim = share;
}
