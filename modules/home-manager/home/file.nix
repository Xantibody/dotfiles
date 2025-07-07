{ self, ... }:
{
  ".config/nvim/init.lua" = {
    source = self + /dotfiles/nvim/init.lua;
  };
  ".config/nvim/lua" = {
    source = self + /dotfiles/nvim/lua;
    recursive = true;
  };
  ".config/fish/config.fish" = {
    source = self + /dotfiles/fish/config.fish;
  };
  ".config/efm-langserver/config.yaml" = {
    source = self + /dotfiles/efm-langserver/config.yaml;
  };
  ".skk/SKK-JISYO.L" = {
    source = self + /dotfiles/skk/SKK-JISYO.L;
  };
  ".config/zellij/config.kdl" = {
    source = self + /dotfiles/zellij/config.kdl;
  };
  ".config/waybar" = {
    source = self + /dotfiles/waybar;
    recursive = true;
  };
  ".config/rofi" = {
    source = self + /dotfiles/rofi;
    recursive = true;
  };
  ".config/k9s" = {
    source = self + /dotfiles/k9s;
    recursive = true;
  };
}
