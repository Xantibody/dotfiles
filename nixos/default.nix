{ 
  inputs,
#  config,
  pkgs, 
  xremap,
  ... 
}:
let
  configuration = import ./configuration.nix { inherit pkgs; };
in 
{
  import = [
    configuration
     xremap.nixosModules.default
  ];
}
