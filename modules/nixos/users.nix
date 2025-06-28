{ pkgs, ... }:
{
  users.raizawa = {
    isNormalUser = true;
    description = "r-aizawa";
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };
}
