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
      vendorHash = "sha256-7K17JaXFsjf163g5PXCb5ng2gYdotnZ2IDKk8KFjNj0=";
      ldflags = [
        "-s"
        "-w"
        "-X main.buildVersion=${version}"
      ];
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
    { pkgs, ... }:
    {
      home.packages = [ (mkRat pkgs) ];
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
