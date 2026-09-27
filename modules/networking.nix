# ネットワークと ssh-agent。ホスト名は host 側 (modules/hosts/) が決める。
{
  flake.modules.nixos.networking = {
    networking.networkmanager.enable = true;
    programs.ssh.startAgent = true;
  };
}
