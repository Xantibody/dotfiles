# シェルを開いたときに出るもの: プロンプト、ディレクトリ移動、環境の自動読み込み。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.prompt ];
  };
in
{
  flake.modules.homeManager.prompt = {
    programs = {
      starship.enable = true;
      zoxide.enable = true;
      fastfetch.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };

  flake.modules.darwin.prompt = share;
  flake.modules.nixos.prompt = share;
}
