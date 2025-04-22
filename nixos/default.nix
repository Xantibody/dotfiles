{ 
  inputs,
  pkgs, 
  xremap,
  hyprpanel,
  ... 
}:
let
  configuration = import ./configuration.nix { inherit pkgs hyprpanel; };
in
{
  imports = [
    configuration
    xremap.nixosModules.default
  ];
}
