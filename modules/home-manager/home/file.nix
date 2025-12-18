{ self, ... }:
{
  # nvim の init.lua, lua/ は NixVim で管理
  # dictionary は blink-cmp-dictionary で使用するため残す
  ".config/nvim/dictionary" = {
    source = self + /configs/nvim/dictionary;
  };
  ".config/efm-langserver/config.yaml" = {
    source = self + /configs/efm-langserver/config.yaml;
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
  ".config/yamlfmt/yamlfmt.yaml" = {
    source = self + /configs/yamlfmt/yamlfmt.yaml;
  };
  ".claude/CLAUDE.md" = {
    source = self + /configs/claude/CLAUDE.md;
  };
  ".claude/commands" = {
    source = self + /configs/claude/commands;
    recursive = true;
  };
  ".claude/skills" = {
    source = self + /configs/claude/skills;
    recursive = true;
  };
}
