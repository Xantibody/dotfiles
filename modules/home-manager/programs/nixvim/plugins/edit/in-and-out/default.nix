{ pkgs, ... }:
let
  in-and-out-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "in-and-out-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "ysmb-wtsg";
      repo = "in-and-out.nvim";
      rev = "03456b9c49365a28732378a7f2a72a613154e042";
      sha256 = "sha256-QPEvWOTKzscUs+vHQ0LJ/BNBd9buMgG/jkmjg7JlhT8=";
    };
  };
in
{
  extraPlugins = [
    in-and-out-nvim
  ];

  # 例: In-and-Out のための推奨設定をここに書くことができます
  # extraConfigLua = ''
  #   vim.keymap.set('i', '<Tab>', function()
  #     return require('in-and-out').in_and_out()
  #   end, { expr = true })
  # '';
}
