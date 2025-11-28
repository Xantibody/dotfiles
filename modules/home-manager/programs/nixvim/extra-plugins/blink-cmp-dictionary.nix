# blink.cmp依存のためdoCheck無効
{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "blink-cmp-dictionary";
  doCheck = false;
  src = pkgs.fetchFromGitHub {
    owner = "Kaiser-Yang";
    repo = "blink-cmp-dictionary";
    rev = "944b3b215b01303672d4213758db7c5c5a1e3c92";
    sha256 = "sha256-e8ucufhLdNnE8fBjSLaTJngEj1valYE9upH78y+wj4I=";
  };
}
