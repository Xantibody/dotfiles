{ pkgs, ... }:
with pkgs;
[
  kustomize
  kubernetes-helm
  yq-go
  dyff
  kubeconform
  kubernetes-helm
  k9s
]
