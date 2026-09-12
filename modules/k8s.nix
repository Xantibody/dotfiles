# Kubernetes 周り。k9s の設定も含む。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.k8s ];
  };
in
{
  flake.modules.homeManager.k8s =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kustomize
        kubernetes-helm
        yq-go
        dyff
        kubeconform
        kubernetes-helm
        k9s
      ];
      home.file.".config/k9s" = {
        source = ../configs/k9s;
        recursive = true;
      };
    };

  flake.modules.darwin.k8s = share;
  flake.modules.nixos.k8s = share;
}
