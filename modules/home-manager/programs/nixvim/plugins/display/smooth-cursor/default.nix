{ pkgs, ... }:
let
  smooth-cursor-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "SmoothCursor-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "gen740";
      repo = "SmoothCursor.nvim";
      rev = "12518b284e1e3f7c6c703b346815968e1620bee2";
      sha256 = "sha256-P0jGm5ODEVbtmqPGgDFBPDeuOF49CFq5x1PzubEJgaM=";
    };
  };
in
{
  # プラグインの登録
  extraPlugins = [
    smooth-cursor-nvim
  ];

  # 設定コードの登録
  # 元のコードが 'lua require(...)' 形式だったので、そのまま Lua として渡します
  extraConfigLua = ''
    require("smoothcursor").setup({ texthl = "SmoothCursorGreen" })
  '';
}
