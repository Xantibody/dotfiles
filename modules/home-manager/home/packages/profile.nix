# ~/.claude/skills/profile が呼ぶ計測ツール。nix shell で都度取り寄せると
# フレームグラフの工程が省かれがちなので、常設して skill の前提にする。
{ pkgs, ... }:
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
++ pkgs.lib.optionals stdenv.hostPlatform.isLinux [
  perf
]
