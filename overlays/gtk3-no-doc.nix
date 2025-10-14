# overlays/gtk3-backport-sincos-fetch.nix
final: prev: {
  gtk3 = prev.gtk3.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (final.fetchpatch {
        # 例: PR内で追加されたパッチファイルの raw（コミットSHAはあなたのPR画面の最新に置換）
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/d675d621d2d0a512b12cd393987408b07ae81b08/pkgs/development/libraries/gtk/patches/3.0-clang-tests-sincos.patch";
        hash = "sha256-uNoMQnoMr4zfKsYiMjIOkI4s2CEKArtaqt/y4rk6AYE=";
      })
    ];
  });
}
