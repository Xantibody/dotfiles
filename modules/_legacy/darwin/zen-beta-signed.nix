# 署名保持版 Zen Beta (macOS) — 1Password 連携を成立させるための配置調整。
#
# 問題1 (署名) は解決済み: かつて zen-browser-flake の installDarwin は公式署名済み
#   .app を改変後に `/usr/bin/codesign --sign -` で ad-hoc 再署名し、Zen 元来の
#   Apple Developer 署名 (Team ID 9V5K9TP787) を剥がしていた。upstream は PR #212 を
#   取り込まず、同等の修正を 17a400c として main に入れており、現在の installDarwin は
#   .app を一切改変しない。よって署名目的の override はもう不要。
#
# 問題2 (配置) は未解決なので、以下の installPhase override が残っている:
#   1Password の native core は署名が正しくても /nix/store 配置のブラウザを検証で
#   拒否する (BrowserVerificationFailed)。このパッケージを environment.systemPackages
#   に入れ、nix-darwin に標準ロケーション /Applications/Nix Apps/ へ署名保持コピー
#   させることで回避する。
#   upstream の launcher は home-manager 前提で
#   `$HOME/Applications/Home Manager Apps/` を見にいくが、ここは systemPackages 経由の
#   配置なのでそのパスは存在せず、/nix/store へフォールバックして 1Password に弾かれる。
#   そのため launcher の STABLE_PATH だけを /Applications/Nix Apps/ に差し替える。
#   (upstream をそのまま使えるようになるのは 1Password が /nix/store を受け付けた場合のみ)
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
