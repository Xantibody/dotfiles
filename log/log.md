### 2025-04-08
- nmcliでなんとかwifi繋げた
- nmtuiなるものもあるらしいぜ
- 次回はnixの分割を学ぶぜ

### 2025-04-10
- nix分割で解読できなかった
- default.nixでnixosを読みこんでるのわかった
- これであとは書いてみるだけ、細かい記述を次回やる

### 2025-04-11
- flakeだけそれっぽく書いた
- homemanagerとcoufigurationの設定あたりを調整する必要あり
- homemanagerを次は移管してみる

### 2025-04-14
- ひたすらエラーログを解決
- dry-run は `sudo nixos-rebuild dry-build --flake .#E14Gen6 --show-trace`でできるらしい
- xremapが引数としてないとかnixos/default.nixで言われるのを解決する

### 2025-04-28
- 時を戻した
- 取り敢えずhome-managerが悪いのは判ったのでちゃんとドキュメントを読む
- エラーを斜め読みせずにやるぞ!

### 2025-04-30
- nixos dry-buildは動いた
- switchではusernameがコンフリクトかなにおこしていてだめだった
- 次はそこを解決する!!!
