{
  enable = true;
  settings = builtins.fromTOML (builtins.readFile ./starship.toml);
}
