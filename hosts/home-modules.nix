{ inputs }:
[
  # nixCats neovim configuration
  ../modules/home-manager/programs/nixcats
  inputs.nix-index-database.homeModules.default
  { programs.nix-index-database.comma.enable = true; }
]
