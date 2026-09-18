# Claude Code の PreToolUse hook (Bash 向け)。
# gh pr / issue の create・edit・comment が --body-file に渡すファイルを lint-body にかけ、
# 指摘があれば exit 2 でコマンドを止める。stderr はそのまま Claude に返る。
# 各 Bash 呼び出しは別プロセスなので、--body-file の値は変数展開なしのリテラルなパスでないと辿れない。
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

if ! grep -Eq 'gh (pr|issue) (create|edit|comment)' <<<"$cmd"; then
  exit 0
fi

if grep -Eq -- '(^|[[:space:]])(--body|-b)([[:space:]=]|$)' <<<"$cmd"; then
  echo "本文は --body ではなく --body-file で渡す。lint-body にかけられないので止めた" >&2
  exit 2
fi

if [[ ! $cmd =~ --body-file[=[:space:]]+(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]+)) ]]; then
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
