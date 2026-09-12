# Nix で入れた .app を Spotlight と Dock から普通のアプリとして扱えるようにする。
# /nix/store 直下の .app は macOS のランチャから見えないので、mac-app-util が
# /Applications 以下に trampoline を置く。
{ inputs, ... }:
{
  flake.modules.darwin.spotlight = {
    imports = [ inputs.mac-app-util.darwinModules.default ];
    home-manager.sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
  };
}
