{ pkgs, ... }:
{
  users.raizawa = {
    isNormalUser = true;
    description = "r-aizawa";
    shell = pkgs.fish;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
  };
}
