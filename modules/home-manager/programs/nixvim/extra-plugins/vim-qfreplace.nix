{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "vim-qfreplace";
  src = pkgs.fetchFromGitHub {
    owner = "thinca";
    repo = "vim-qfreplace";
    rev = "707a895f9f86eeed106f64da0bd9fa07b3cd9cee";
    sha256 = "sha256-6G89NznCOumLIJb2l8szKGIWMr3CtpeHUfdkzEOCo8U=";
  };
}
