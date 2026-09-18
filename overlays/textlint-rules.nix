# nixpkgs にまだ無い textlint ルール。どちらも package-lock.json を持つので buildNpmPackage で足りる。
# textlint.withPackages が NODE_PATH に載せるのは $out/lib/node_modules/<name> で、
# npmInstallHook がそこへ置くので nixpkgs の textlint-rule-* と同じ形になる。
final: prev:
let
  inherit (prev) lib buildNpmPackage fetchFromGitHub;
in
{
  # AIDEV-NOTE: nixpkgs に上げる候補。上流に入ったら overlay ごと消して pkgs のものを使う
  textlint-rule-preset-ai-writing = buildNpmPackage (finalAttrs: {
    pname = "textlint-rule-preset-ai-writing";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "textlint-ja";
      repo = "textlint-rule-preset-ai-writing";
      tag = "v${finalAttrs.version}";
      hash = "sha256-mEi17KZLic5Uzr7NthAM47TqQsCUy6RyknBWB7tTZBc=";
    };

    npmDepsHash = "sha256-YO4uJMR894Z3vtyqpSBvKifr/aFIZMACwKdCGbrQybE=";

    # 上流の lock は 361 個の依存に resolved URL が無く、Nix の offline cache に載らない。
    # npm-lockfile-fix で埋め直したものを同梱する (fetchNpmDeps も postPatch 後の lock を読む)。
    # prepare は git hooks を設定しようとして、git の無いビルド環境で落ちるので消す。
    postPatch = ''
      cp ${./textlint-rule-preset-ai-writing.package-lock.json} package-lock.json
      substituteInPlace package.json \
        --replace-fail '"prepare": "git config --local core.hooksPath .githooks",' ""
    '';

    meta = {
      description = "AI っぽい記述パターンを検出し、自然な日本語表現を促す textlint プリセット";
      homepage = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing";
      changelog = "https://github.com/textlint-ja/textlint-rule-preset-ai-writing/blob/v${finalAttrs.version}/release-notes.md";
      license = lib.licenses.mit;
      platforms = prev.textlint.meta.platforms;
    };
  });

  textlint-rule-ja-hiraku = buildNpmPackage (finalAttrs: {
    pname = "textlint-rule-ja-hiraku";
    version = "1.4.0";

    src = fetchFromGitHub {
      owner = "akiomik";
      repo = "textlint-rule-ja-hiraku";
      tag = "v${finalAttrs.version}";
      hash = "sha256-Jz8k616uVCfRIL0HwL3f62eduOIpv2h1upQGz4Rj81c=";
    };

    npmDepsHash = "sha256-+atlEg86tQ51+e4hSKf4NGUp+c/ri2fKhp86B3liZHc=";

    meta = {
      description = "漢字をひらく textlint ルール";
      homepage = "https://github.com/akiomik/textlint-rule-ja-hiraku";
      changelog = "https://github.com/akiomik/textlint-rule-ja-hiraku/releases/tag/v${finalAttrs.version}";
      license = lib.licenses.mit;
      platforms = prev.textlint.meta.platforms;
    };
  });
}
