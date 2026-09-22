# Claude Code の PreToolUse hook (Edit / Write 向け)。
# 編集しようとしているファイルとその dir にある anchor コメントを additionalContext で返し、
# 「編集前に anchor を読む」を指示ではなく仕組みにする。見つからなければ何も出さない。
set -euo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[[ -n $file && -e $file ]] || exit 0

dir=$(dirname "$file")
found=$(cd "$dir" && rg -n --no-heading --max-depth 1 --color never 'HACK\(|AIDEV-' . 2>/dev/null | sed 's|^\./||' | head -40 || true)
[[ -n $found ]] || exit 0

jq -n --arg ctx "Anchors in $dir (read before editing; update the one above code you change):"$'\n'"$found" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
