{ pkgs, ... }:
let
  jsonFormat = pkgs.formats.json { };
  mdsfConfig = builtins.fromJSON (builtins.readFile ./mdsf.json);
in
{
  home.file.".mdsf.json".source = jsonFormat.generate "mdsf.json" mdsfConfig;
}
