{ pkgs, username, homeDirectory, ... }:
{
  users = {
    users = {
      "${username}" = {
        name = username;
        home = homeDirectory;
        shell = pkgs.fish;
      };
    };
  };
}
