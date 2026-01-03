{ pkgs, ... }:
{
  plugins.flash.enable = true;

  keymaps =
    let
      options = {
        silent = true;
        noremap = true;
      };
    in
    [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action = "<cmd>lua require('flash').jump()<CR>";
        inherit options;
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action = "<cmd>lua require('flash').treesitter()<CR>";
        inherit options;
      }
      {
        mode = [ "o" ];
        key = "r";
        action = "<cmd>lua require('flash').remote()<CR>";
        inherit options;
      }
      {
        mode = [
          "o"
          "x"
        ];
        key = "R";
        action = "<cmd>lua require('flash').treesitter_search()<CR>";
        inherit options;
      }
      {
        mode = [ "c" ];
        key = "<c-s>";
        action = "<cmd>lua require('flash').toggle()<CR>";
        inherit options;
      }
    ];
}
