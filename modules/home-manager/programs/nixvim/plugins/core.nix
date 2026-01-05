# コアプラグイン: treesitter, telescope, oil, neogit, gitsigns, barbar, hlchunk
{ pkgs, ... }:
{
  # Treesitter
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = true;
      indent.enable = true;
      incremental_selection = {
        enable = true;
        keymaps = {
          init_selection = "<C-space>";
          node_incremental = "<C-space>";
          scope_incremental = false;
          node_decremental = "<bs>";
        };
      };
    };
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      css
      dockerfile
      gitignore
      html
      java
      javascript
      json
      lua
      markdown
      markdown_inline
      python
      rust
      toml
      vim
      yaml
      go
      nix
      fish
      typescript
    ];
  };

  # ts-autotag
  plugins.ts-autotag.enable = true;

  # Barbar
  plugins.barbar.enable = true;

  # Which-key
  plugins.which-key.enable = true;

  # fzf-lua
  plugins.fzf-lua.enable = true;

  # Mini icons
  plugins.mini = {
    enable = true;
    modules.icons = { };
  };

  # Web devicons
  plugins.web-devicons.enable = true;
}
