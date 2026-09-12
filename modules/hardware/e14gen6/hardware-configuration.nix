# nixos-generate-config が吐いたものをそのまま module として載せる。
{
  flake.modules.nixos.hardware-configuration = ./_hardware-configuration.nix;
}
