# nixpkgs の実体を 1 つに保つ。
# 以前は host ごとに `import nixpkgs { overlays = ...; }` を手で呼び、それを
# specialArgs の pkgs として配っていたので、module system が組む
# config.nixpkgs.pkgs と二重に instantiate される形になっていた。
{ inputs, ... }:
let
  # TODO: ここに残っている overlay は、それぞれの機能のファイルへ移していく
  common = [
    (final: _prev: {
      ichigyo-ls = inputs.ichigyo-ls.packages.${final.stdenv.hostPlatform.system}.default;
    })
    inputs.firefox-addons.overlays.default
  ];
  darwinOnly = [
    (final: _prev: {
      arto = inputs.arto.packages.${final.stdenv.hostPlatform.system}.default;
    })
    inputs.brew-nix.overlays.default
  ];
  own = import ../../overlays;
in
{
  flake.modules.darwin.nixpkgs = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = common ++ darwinOnly ++ own;
  };

  flake.modules.nixos.nixpkgs = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = common ++ own;
  };
}
