{pkgs,...}:{
  users.raizawa = {
    isNormalUser = true;
    description = "r-aizawa";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.fish;
  };
}
