# Claude Code のネイティブインストーラが落とす汎用 Linux バイナリは interpreter が
# /lib64/ld-linux-x86-64.so.2 固定で、FHS でない NixOS ではそのままだと起動できない。
# nix-ld はその位置に shim を置くので、自動更新で新しいバイナリが落ちてきても効き続ける。
# AIDEV-NOTE: patchelf は自動更新のたびに壊れ、pkgs.claude-code も自前更新で同じ問題に戻るので採らない
# 必要な libstdc++ / zlib / openssl はモジュールのデフォルト libraries に含まれている。
{ enable = true; }
