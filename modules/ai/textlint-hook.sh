# Claude Code の PreToolUse hook (Bash 向け)。
# gh pr / issue の create・edit・comment が --body-file に渡すファイルを lint-body にかけ、
# 指摘があれば exit 2 でコマンドを止める。stderr はそのまま Claude に返る。
# 各 Bash 呼び出しは別プロセスなので、--body-file の値は変数展開なしのリテラルなパスでないと辿れない。
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

# heredoc や echo の中身に gh の呼び出しが書かれていても発火しないよう、まず heredoc の
# 本文を落とし、コマンド位置 (行頭か && ; | の直後) にある gh だけを見る。
# 報告書を heredoc で書くと本文に gh の例が入るので、これが無いと lint が二重にかかる。
stripped=""
delim=""
while IFS= read -r l; do
  if [[ -n $delim ]]; then
    [[ ${l#"${l%%[! 	]*}"} == "$delim" ]] && delim=""
    continue
  fi
  if [[ $l =~ \<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]? ]]; then
    delim=${BASH_REMATCH[1]}
  fi
  stripped+="$l"$'\n'
done <<<"$cmd"

line=$(grep -E '(^|&&|;|\|)[[:space:]]*gh (pr|issue) (create|edit|comment)' <<<"$stripped" | head -1 || true)
if [[ -z $line ]]; then
  exit 0
fi
line=${line#*gh }
line="gh $line"

if grep -Eq -- '(^|[[:space:]])(--body|-b)([[:space:]=]|$)' <<<"$line"; then
  echo "本文は --body ではなく --body-file で渡す。lint-body にかけられないので止めた" >&2
  exit 2
fi

if [[ ! $line =~ --body-file[=[:space:]]+(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]+)) ]]; then
  exit 0
fi
path="${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}"

if [[ $path == *'$'* || $path == *'('* ]]; then
  echo "--body-file は変数や置換ではなくリテラルなパスで渡す。hook はこの Bash 呼び出しの外の値を見られない: $path" >&2
  exit 2
fi
if [[ $path != /* ]]; then
  path="$cwd/$path"
fi
if [[ ! -f $path ]]; then
  echo "--body-file が見つからない: $path" >&2
  exit 2
fi

if ! result=$(lint-body "$path" 2>&1); then
  echo "本文に textlint の指摘が残っている。直してから再実行する (fix 可能なものは lint-body --fix $path)" >&2
  echo "$result" >&2
  exit 2
fi
