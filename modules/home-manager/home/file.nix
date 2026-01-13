{ self, ... }:
{
  # dictionary は blink-cmp-dictionary で使用
  ".config/nvim/dictionary" = {
    source = self + /configs/dictionary;
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
  ".claude/skills" = {
    source = self + /configs/claude/skills;
    recursive = true;
  };
  ".claude/settings.json" = {
    source = self + /configs/claude/settings.json;
  };
}
