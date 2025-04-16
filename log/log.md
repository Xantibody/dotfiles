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
