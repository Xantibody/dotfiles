# CI が 3 host すべての評価を見るようにする。
# `nix flake check` が自動で評価するのは nixosConfigurations.<name>.config.system.
# build.toplevel までで、darwinConfigurations は対象外。mac 2 台の設定を壊しても
# PR が緑のままだったので、drvPath を書き出すだけの derivation を checks に置く。
#
# AIDEV-NOTE: unsafeDiscardStringContext が要る。drvPath の string context を残すと
# checks のビルドがその system 本体のビルドになり、Linux の構成まで手元で組み始める。
{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      hosts = config.flake.darwinConfigurations // config.flake.nixosConfigurations;
    in
    {
      checks = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "eval-${name}" (
          pkgs.writeText "eval-${name}" (
            builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath
          )
        )
      ) hosts;
    };
}
