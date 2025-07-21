{ self, ... }:
{
  ".config/nvim/init.lua" = {
    source = self + /configs/nvim/init.lua;
  };
  ".config/nvim/dictionary" = {
    source = self + /configs/nvim/dictionary;
  };
  ".config/nvim/lua" = {
    source = self + /configs/nvim/lua;
    recursive = true;
  };
  ".config/efm-langserver/config.yaml" = {
    source = self + /configs/efm-langserver/config.yaml;
  };
  ".skk/SKK-JISYO.L" = {
    source = self + /configs/skk/SKK-JISYO.L;
  };
  ".config/zellij/config.kdl" = {
    source = self + /configs/zellij/config.kdl;
  };
  ".config/waybar" = {
    source = self + /configs/waybar;
    recursive = true;
  };
  ".config/rofi" = {
    source = self + /configs/rofi;
    recursive = true;
  };
  ".config/k9s" = {
    source = self + /configs/k9s;
    recursive = true;
  };
  ".via/via.json" = {
    source = self + /configs/via/via.json;
  };
}
