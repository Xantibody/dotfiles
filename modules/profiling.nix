# ~/.claude/skills/profile が呼ぶ計測ツール。nix shell で都度取り寄せると
# フレームグラフの工程が省かれがちなので、常設して skill の前提にする。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    home-manager.sharedModules = [ hm.profiling ];
  };
in
{
  flake.modules.homeManager.profiling =
    { pkgs, lib, ... }:
    {
      home.packages =
        with pkgs;
        [
          # flamegraph.pl / stackcollapse-*.pl / difffolded.pl
          flamegraph
          # FlameGraph の Rust 移植。inferno-collapse-xctrace が macOS Instruments を folded に変換する
          inferno
          hyperfine
          py-spy
          cargo-flamegraph
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ perf ];
    };

  flake.modules.darwin.profiling = share;
  flake.modules.nixos.profiling = share;
}
