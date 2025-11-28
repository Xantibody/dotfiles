{ pkgs }:
pkgs.vimUtils.buildVimPlugin {
  name = "skkeleton";
  src = pkgs.fetchFromGitHub {
    owner = "vim-skk";
    repo = "skkeleton";
    rev = "3e019b331fbf9bd1d4539e7bd650a1c543125cee";
    sha256 = "sha256-VDu8WypgpzY+Dd8KIPJXsvtBEwt5YiuGXn6HAUKCbIQ=";
  };
}
