{ pkgs, ... }:
{
  packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    explex-nf
  ];
}
