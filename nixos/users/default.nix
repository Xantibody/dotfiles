{ pkgs, ... }:
{
  users.raizawa = {
    isNormalUser = true;
    description = "raizawa";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };
}
