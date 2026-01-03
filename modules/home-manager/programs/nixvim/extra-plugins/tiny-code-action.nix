{ pkgs, ... }:
let
  # tiny-code-action 本体のみをビルド定義
  tiny-code-action-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "tiny-code-action-nvim";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-tiV+drfWAryw8cexSCgmZCXfHxi4oi6qX6oNmhHrhAk=";
    };
  };
in
{
  # 1. サポートされているプラグインは enable で有効化
  plugins.snacks = {
    enable = true;
  };

  # 2. 未サポートのプラグインのみ extraPlugins に登録
  extraPlugins = [
    tiny-code-action-nvim
  ];

  # 3. Lua設定
  extraConfigLua = ''
    require("tiny-code-action").setup({})
  '';
}
