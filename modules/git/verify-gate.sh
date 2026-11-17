# コミットに検証の有無を Verified-by trailer で残す commit gate。
#
#   verify-gate run [--] <command>...   command を走らせ、成功したら今の作業ツリーの tree に記録する
#   verify-gate commit-msg <file>       git の commit-msg hook。コミットする tree の記録を trailer にする
#
# 記録は <git-common-dir>/verify-gate/<tree> に 1 行 1 コマンドで置く。tree は内容のハッシュなので、
# 検証の後に 1 文字でも変えたり、作業ツリーの一部だけをコミットしたりすると一致せず none になる。
# モードは `git config verify.gate` で、未設定と off は何もしない、observe は止めずに記録だけする。
# AIDEV-NOTE: enforce (検証の無いコミットを止める) は observe で誤検知を見てから入れる。今は未実装として落とす
set -euo pipefail

die() {
  echo "verify-gate: $*" >&2
  exit 1
}

records_dir() {
  echo "$(git rev-parse --path-format=absolute --git-common-dir)/verify-gate"
}

# 作業ツリーそのもの (追跡外でも ignore されていないファイルを含む) の tree。
# 一時 index に積むので、ユーザーの index には触らない
worktree_tree() {
  local tmp index
  tmp=$(mktemp -d)
  index=$(git rev-parse --path-format=absolute --git-path index)
  if [[ -f $index ]]; then
    cp "$index" "$tmp/index"
  fi
  GIT_INDEX_FILE="$tmp/index" git add -A
  GIT_INDEX_FILE="$tmp/index" git write-tree
  rm -f "$tmp/index"
  rmdir "$tmp"
}

cmd_run() {
  [[ ${1:-} == -- ]] && shift
  (($# > 0)) || die "usage: verify-gate run [--] <command>..."
  local status=0 label prefix tree dir
  "$@" || status=$?
  if ((status != 0)) || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit "$status"
  fi
  label="$*"
  prefix=$(git rev-parse --show-prefix)
  [[ -z $prefix ]] || label="$label (in ${prefix%/})"
  # command が整形などでファイルを書き換えることがあるので、tree は走らせた後に取る
  tree=$(worktree_tree)
  dir=$(records_dir)
  mkdir -p "$dir"
  touch "$dir/$tree"
  grep -Fxq -- "$label" "$dir/$tree" || printf '%s\n' "$label" >>"$dir/$tree"
  echo "verify-gate: recorded '$label' for tree $tree" >&2
}

cmd_commit_msg() {
  local msg=${1:?usage: verify-gate commit-msg <file>} mode tree file
  mode=$(git config --get verify.gate || true)
  case $mode in
  "" | off) exit 0 ;;
  observe) ;;
  enforce) die "verify.gate=enforce is not implemented yet; set it to observe or off" ;;
  *) die "unknown verify.gate value '$mode'; set it to observe or off" ;;
  esac
  # 本文が空ならコミット自体を git が中止する。trailer を足すと空でなくなり、中止したつもりのコミットが通る
  [[ -n $(git stripspace --strip-comments <"$msg") ]] || exit 0

  # amend では前の trailer が残っているので、消してから今の tree で付け直す
  grep -v '^Verified-by: ' "$msg" >"$msg.verify-gate" || true
  mv "$msg.verify-gate" "$msg"

  # hook の中では git が GIT_INDEX_FILE を渡すので、write-tree は `commit -a` やパス指定でもコミットする tree を返す
  tree=$(git write-tree)
  file="$(records_dir)/$tree"
  local -a trailers=()
  if [[ -s $file ]]; then
    while IFS= read -r line; do
      trailers+=(--trailer "Verified-by: $line")
    done <"$file"
  else
    trailers=(--trailer "Verified-by: none")
  fi
  git interpret-trailers --in-place "${trailers[@]}" "$msg"
}

case ${1:-} in
run)
  shift
  cmd_run "$@"
  ;;
commit-msg)
  shift
  cmd_commit_msg "$@"
  ;;
*) die "usage: verify-gate run [--] <command>... | verify-gate commit-msg <file>" ;;
esac
