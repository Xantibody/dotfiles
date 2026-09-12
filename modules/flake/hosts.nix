# 実機 1 台につき 1 つの構成。中身は hosts/ から順に modules/ へ移していく。
{ inputs, ... }:
{
  flake = {
    nixosConfigurations = {
      E14Gen6 = import ../../hosts/E14Gen6 { inherit inputs; };
    };
    darwinConfigurations = {
      work-macbook-pro-m4-attm = import ../../hosts/work-macbook-pro-m4-attm { inherit inputs; };
      private-macbook-pro-m3 = import ../../hosts/private-macbook-pro-m3 { inherit inputs; };
    };
  };
}
