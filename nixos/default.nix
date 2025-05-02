{ 
  inputs,
  pkgs, 
  xremap,
  ... 
}:
let
  configuration = import ./configuration.nix { inherit pkgs; };
in 
{
  imports = [
    configuration
     xremap.nixosModules.default
  ];
}
