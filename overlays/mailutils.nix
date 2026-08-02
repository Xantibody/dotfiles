# overlays/mailutils.nix
#
# mailutils 3.21 は aarch64-darwin + libtool 2.6.2 でリンクに失敗する。
# libmu_sieve のローダブルモジュールが libmailutils のシンボルを直接
# リンクせずに参照しているため (ld: symbol(s) not found for architecture arm64)。
# upstream bug: https://savannah.gnu.org/bugs/?68588
# nixpkgs PR: https://github.com/NixOS/nixpkgs/pull/548382 (未マージ)
#
# emacs.override { withMailutils = false; } でも回避できるが、それだと
# movemail を失うため、PR のパッチをそのまま先取りする。PR がマージされたら
# このオーバーレイは削除する。
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  mailutils = prev.mailutils.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/6f01de0cfe9b170f415b2552fd2902891868e28c/pkgs/by-name/ma/mailutils/fix-linking-with-libtool-2.6.2.patch";
        hash = "sha256-gnhPMXVX9u0J6JYaLwOMf9yzuUVWfIP8x247MyYVv08=";
      })
    ];
  });
}
