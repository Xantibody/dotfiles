{
  pkgs,
  username,
  homeDirectory,
  ...
}:
let
  configuration =
    (import ./users.nix { inherit pkgs username homeDirectory; })
    // {
      environment = import ./environment.nix { inherit pkgs; };
    }
    // {
      nix = import ./nix.nix;
    }
    // {
      programs = import ./programs.nix;
    }
    // {
      homebrew = import ./homebrew.nix;
    }
    // {
      security = import ./security.nix;
    }
    // {
      fonts = import ./fonts.nix { inherit pkgs; };
    }
    // {
      system = import ./system.nix { inherit pkgs username; };
    }
    // {
      services = import ./services.nix;
    }
    // (import ./options.nix { inherit pkgs; })
    // {
      ids.gids.nixbld = 350;
    };
in
{
  imports = [
    configuration
  ];
}
