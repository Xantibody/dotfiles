# 編集前に anchor を見せる PreToolUse hook (anchors-hook.sh)。
# 「編集前に anchor を読む」を指示ではなく仕組みにする。settings.json が Edit / Write に名前で登録する。
#
# claude feature の一部なので `_` 始まりにして import-tree から外し、claude.nix が imports で読む。
{ ... }:
let
  mkAnchorsHook =
    pkgs:
    pkgs.writeShellApplication {
      name = "anchors-hook";
      runtimeInputs = [
        pkgs.jq
        pkgs.ripgrep
      ];
      text = builtins.readFile ./anchors-hook.sh;
    };
in
{
  flake.modules.homeManager.anchors-hook =
    { pkgs, ... }:
    {
      home.packages = [ (mkAnchorsHook pkgs) ];
    };
}
