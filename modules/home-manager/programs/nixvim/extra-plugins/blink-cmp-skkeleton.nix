{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "blink-cmp-skkeleton";
  src = pkgs.fetchFromGitHub {
    owner = "Xantibody";
    repo = "blink-cmp-skkeleton";
    rev = "main";
    sha256 = "sha256-uzDqykavZlQcqLi/7Bqi72Pt/5zFdAqkyN73xm/KxFw=";
  };
}
