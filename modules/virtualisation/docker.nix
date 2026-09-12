# Docker。ユーザを docker グループへ入れるのは modules/base/user.nix。
{
  flake.modules.nixos.docker = {
    virtualisation.docker.enable = true;
  };
}
