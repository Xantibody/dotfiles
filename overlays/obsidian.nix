# overlays/obsidian.nix
#
# nixpkgs の obsidian (darwin) は sourceRoot = "Obsidian.app" 固定だが、
# 1.13.4 の DMG は "Obsidian <version>-universal/Obsidian.app" のように
# ボリュームフォルダ配下へ .app を展開するため unpack 後に見つからず失敗する。
# version 決め打ちにせず glob で辿るのは、次のバージョンでフォルダ名が
# 変わっても追従させるため。
# nixpkgs issue: https://github.com/NixOS/nixpkgs/issues/548445
# 修正が入ったらこのオーバーレイは削除する。
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  obsidian = prev.obsidian.overrideAttrs (_old: {
    sourceRoot = null;
    setSourceRoot = ''
      sourceRoot=$(echo */Obsidian.app)
    '';
  });
}
