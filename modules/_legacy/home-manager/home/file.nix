# source は module ファイルからの相対 path literal で書く。
# `self + /configs/x` は先頭が attrset なので path のコピーではなく flake 全体の
# store path との文字列連結になり、(1) 無関係なファイルを 1 つ変えるだけで
# home-files の derivation が変わる (2) 実体の無いパスでもエラーにならず dangling
# symlink になる、の 2 つが起きていた。path literal はそのサブツリーだけを store へ
# コピーするので、ハッシュはその中身だけで決まり、存在しないパスは評価時に落ちる。
{
  ".config/waybar" = {
    source = ../../../../configs/waybar;
    recursive = true;
  };
  ".config/rofi" = {
    source = ../../../../configs/rofi;
    recursive = true;
  };
  ".via/via.json" = {
    source = ../../../../configs/via/via.json;
  };
}
