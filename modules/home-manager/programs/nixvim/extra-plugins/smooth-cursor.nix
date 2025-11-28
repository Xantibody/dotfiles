{ pkgs }:
{
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "SmoothCursor-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "gen740";
      repo = "SmoothCursor.nvim";
      rev = "12518b284e1e3f7c6c703b346815968e1620bee2";
      sha256 = "sha256-P0jGm5ODEVbtmqPGgDFBPDeuOF49CFq5x1PzubEJgaM=";
    };
  };
  config = ''lua require("smoothcursor").setup({ texthl = "SmoothCursorGreen" })'';
}
