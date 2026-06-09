# 署名保持版 Zen Beta (macOS) — 1Password 連携を成立させるための2つの問題を解決する。
#
# 問題1 (署名): zen-browser-flake の installDarwin は公式署名済み .app を改変後に
#   `/usr/bin/codesign --sign -` で ad-hoc 再署名し、Zen 元来の Apple Developer
#   署名 (Team ID 9V5K9TP787) を剥がす。1Password はこれを署名検証で拒否し、
#   macOS 26 では Gatekeeper も「壊れている」と弾く。
#   対策: .app を一切改変しない installPhase に差し替え、Developer ID 署名・公証を温存。
#   → upstream PR #212 が同じ修正を入れる。マージ後はこの installPhase override を
#     外し、flake の beta-unwrapped をそのまま使えるようになる。
#
# 問題2 (配置): 1Password の native core は署名が正しくても /nix/store 配置の
#   ブラウザを検証で拒否する (BrowserVerificationFailed)。
#   対策: このパッケージを environment.systemPackages に入れ、nix-darwin に
#     標準ロケーション /Applications/Nix Apps/ へ署名保持コピーさせる。
#   → こちらは PR #212 後も必要 (1Password が /nix/store を受け付けないため)。
#
# プロファイル/拡張/設定は home-manager の programs.zen-browser が package = null で
# 別途管理し、Dock は /Applications/Nix Apps/ 版を pin する (modules/darwin/system.nix)。
# 1Password 側では「Add Browser」で /Applications/Nix Apps/Zen Browser (Beta).app を
# 一度登録すれば、署名要件ベースで照合されるため rebuild をまたいで有効。
#
# Refs: 0xc000022070/zen-browser-flake#82, #212; zen-browser/desktop#10788
{ inputs, pkgs }:
inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta-unwrapped.overrideAttrs (_: {
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications" "$out/bin"
    cp -r *.app "$out/Applications/Zen Browser (Beta).app"

    cat > "$out/bin/zen-beta" << EOF
    #!/bin/bash
    STABLE_PATH="/Applications/Nix Apps/Zen Browser (Beta).app"
    if [[ -e "\$STABLE_PATH" ]]; then
      exec /usr/bin/open -na "\$STABLE_PATH" --args "\$@"
    else
      exec /usr/bin/open -na "$out/Applications/Zen Browser (Beta).app" --args "\$@"
    fi
    EOF

    chmod +x "$out/bin/zen-beta"
    ln -s "$out/bin/zen-beta" "$out/bin/zen"

    runHook postInstall
  '';
  dontFixup = true;
})
