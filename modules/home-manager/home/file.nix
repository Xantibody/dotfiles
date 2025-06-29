{ self, ... }:
{
  ".config/nvim/init.lua" = {
    source = self + /nvim/init.lua;
  };
  ".config/nvim/lua" = {
    source = self + /nvim/lua;
    recursive = true;
  };
  ".config/fish/config.fish" = {
    source = self + /fish/config.fish;
  };
  ".config/efm-langserver/config.yaml" = {
    source = self + /efm-langserver/config.yaml;
  };
  ".skk/SKK-JISYO.L" = {
    source = self + /skk/SKK-JISYO.L;
  };
  ".config/zellij/config.kdl" = {
    source = self + /zellij/config.kdl;
  };
  ".config/waybar/scripts" = {
    source = self + /waybar/scripts;
    recursive = true;
  };
  ".config/rofi" = {
    source = self + /rofi;
    recursive = true;
  };
}
