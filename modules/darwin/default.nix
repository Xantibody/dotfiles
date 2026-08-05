{
  pkgs,
  username,
  homeDirectory,
  zen-browser,
  # VM に渡す量は機種ごとに違う。物理を超えると Virtualization.framework が
  # 構成を拒否して colima がまったく起動しなくなるので、ホスト側で指定する。
  colima,
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
      security = import ./security.nix;
    }
    // {
      fonts = import ./fonts.nix { inherit pkgs; };
    }
    // {
    }
    // {
      services = import ./services.nix;
    }
    // {
      launchd = import ./launchd.nix { inherit pkgs username colima; };
    }
    // {
      ids.gids.nixbld = 350;
    };
in
{
  imports = [
    configuration
    ./system.nix
  ];
}
