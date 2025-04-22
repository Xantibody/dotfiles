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

### 2025-04-15
- dry-build通った!!
- import記述がimportsだった(optionがリストだからだろう)
- 次はhome-managerを移行して実際buildしてやるぜ

### 2025-04-16
-  error: The option `extraSpecialArgs' does not exist. Definition values: In `/nix/store/jk6xpbfh10gz6q5cqw8b2f7xk0pl7hkv-source/flake.nix'って言われちゃう
-  extraSpecialArgsを見なおしたけど多分大丈夫なんだよな...
-  日をおいて明日やってみる

### 2025-04-17
- home-managerだめだった
- moduleが悪い？
- 今頭わるいから明日見直す

### 2025-04-18
- 同じ問題をどうどう巡りしている...
- overlay.enable = trueってなんだよ
- 次解決しないなら最悪聞くか...

### 2025-04-21
- Aiderを使いたかったがうまくいかず
- トークンは発行したが使い方が上手じゃない
- もうすこし詰めれば良くなりそう
