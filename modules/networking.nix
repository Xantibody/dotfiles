# ネットワークと ssh-agent。
{
  flake.modules.nixos.networking =
    { pkgs, ... }:
    {
      networking = {
        networkmanager.enable = true;
        hostName = "nixos"; # Define your hostname.
      };
      programs.ssh.startAgent = true;
      environment.systemPackages = [ pkgs.networkmanager ];
    };
}
