# rat: the agent hooks and helper commands of this repository as one binary,
# one subcommand per tool. The Go module is tools/ (not a flake-parts module);
# this file builds it once and puts it on PATH, so hooks and skills call
# `rat <sub>` instead of each carrying its own go.mod and build.
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  mkRat =
    pkgs:
    pkgs.buildGoModule rec {
      pname = "rat";
      version = "0.1.0";
      src = ../tools;
      vendorHash = "sha256-d67yjSG/bSX+y8VDgEqdH++JerjFWHcsKqTWOcF+cnI=";
      ldflags = [
        "-s"
        "-w"
        "-X main.buildVersion=${version}"
      ];
      # rat verify-gate's tests commit in temporary repositories; rat skill
      # validate's eval commit-hash test reads one (and skips without git)
      nativeCheckInputs = [ pkgs.git ];
      # AIDEV-NOTE: go names the binary after the module's last path element (tools); renamed here rather than moving main.go to tools/cmd/rat, so the root package stays the entry point
      postInstall = ''
        mv $out/bin/tools $out/bin/rat
      '';
      meta.mainProgram = "rat";
    };
  share = {
    home-manager.sharedModules = [ hm.rat ];
  };
in
{
  flake.modules.homeManager.rat =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.rat.package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "The rat build on PATH, for a feature that calls it by store path (verify-gate's git hook)";
      };

      config = {
        my.rat.package = mkRat pkgs;
        home.packages = [ config.my.rat.package ];
      };
    };

  # go test is run by buildGoModule's checkPhase
  perSystem =
    { pkgs, ... }:
    {
      packages.rat = mkRat pkgs;
      checks.rat = mkRat pkgs;
    };

  flake.modules.darwin.rat = share;
  flake.modules.nixos.rat = share;
}
