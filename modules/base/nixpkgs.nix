# nixpkgs の実体を 1 つに保つ。
# 以前は host ごとに `import nixpkgs { overlays = ...; }` を手で呼び、それを
# specialArgs の pkgs として配っていたので、module system が組む
# config.nixpkgs.pkgs と二重に instantiate される形になっていた。
# overlay は機能ごとのファイルが自分で足すので、ここには残っていない。
{ inputs, ... }:
let
  common = {
    nixpkgs.config.allowUnfree = true;
  };
in
{
  flake.modules.darwin.nixpkgs = {
    imports = [ common ];
    # brewCasks.* を生やす。使う側 (apps, clipboard) より先に要る
    nixpkgs.overlays = [ inputs.brew-nix.overlays.default ];
  };

  flake.modules.nixos.nixpkgs = common;
}
