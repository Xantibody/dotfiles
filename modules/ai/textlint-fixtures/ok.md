## なぜやるか

Claude が書く PR 本文は 80 桁で折り返され、GitHub が改行を空白として描画するので日本語の文中に空白が挟まっていた。skill の文章だけでは守られないので、textlint で機械的に止める。

## やったこと

- 本文を textlint にかける `lint-body` を home-manager で配る
- `gh pr create` の直前に hook が同じ検査を回し、指摘が残っていれば止める

## やらなかったこと

- nixpkgs に無いルールは overlay に置いた。上流に上げるのは別の作業にする

## 資料

- https://github.com/textlint-ja/textlint-rule-preset-ai-writing
