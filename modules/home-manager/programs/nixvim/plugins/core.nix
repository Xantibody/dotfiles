# コアプラグイン: treesitter, telescope, oil, neogit, gitsigns, barbar, hlchunk
{ pkgs, ... }:
{
  # Treesitter
  treesitter = {
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
  ts-autotag.enable = true;

  # Telescope
  telescope.enable = true;

  # Oil
  oil = {
    enable = true;
    settings = {
      default_file_explorer = true;
      view_options.show_hidden = true;
    };
  };

  # Neogit
  neogit.enable = true;

  # Gitsigns
  gitsigns.enable = true;

  # Barbar
  barbar.enable = true;

  # Which-key
  which-key.enable = true;

  # fzf-lua
  fzf-lua.enable = true;

  # Mini icons
  mini = {
    enable = true;
    modules.icons = { };
  };

  # Web devicons
  web-devicons.enable = true;
}
