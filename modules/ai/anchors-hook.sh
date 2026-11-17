# Claude Code の PreToolUse hook (Edit / MultiEdit / Write / NotebookEdit 向け)。
# 編集しようとしているファイルとその dir にある anchor コメントを additionalContext で返し、
# 「編集前に anchor を読む」を指示ではなく仕組みにする。
# 編集の前後で anchor の行を数え、減る編集は permissionDecision "ask" でユーザーに確認させる。
# 足した行に issue の URL の無い HACK や TODO / FIXME があれば additionalContext で警告する (止めない)。
# どれにも当たらなければ何も出さない。
# AIDEV-NOTE: URL の無い HACK や bare TODO を exit 2 で止める案は採らない。hook は全リポジトリに効き、流儀の違う仕事や共有のリポジトリで作業が止まる
set -euo pipefail

# 組み立てて書くのは、このファイル自体が modules/ai の anchor 一覧に載らないようにするため
hack='HACK''('
note='AIDEV''-NOTE'
anchor_re='HACK\(|AIDEV''-'

input=$(cat)
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[[ -n $file ]] || exit 0

dir=$(dirname "$file")
found=""
if [[ -e $file ]]; then
  found=$(cd "$dir" && rg -n --no-heading --max-depth 1 --color never "$anchor_re" . 2>/dev/null | sed 's|^\./||' | head -40 || true)
fi

# Write はファイルを丸ごと置き換えるので、減ったかどうかはディスク上の今の中身と比べる。
# 大きなファイルでも引数の長さに当たらないよう --rawfile で渡す
before=(--arg before "")
if [[ -f $file ]] && jq -e '.tool_input | has("content")' >/dev/null <<<"$input"; then
  before=(--rawfile before "$file")
fi

# NotebookEdit は前の cell の中身が入力に無いので、anchor の一覧だけを返す
jq -c "${before[@]}" \
  --arg re "$anchor_re" --arg found "$found" --arg dir "$dir" \
  --arg hack "$hack" --arg note "$note" '
  def anchors: [split("\n")[] | select(test($re))] | length;
  .tool_input as $t
  | (if ($t.edits | type) == "array" then [$t.edits[] | [.old_string // "", .new_string // ""]]
     elif $t | has("content") then [[$before, $t.content // ""]]
     elif $t | has("new_string") then [[$t.old_string // "", $t.new_string // ""]]
     else [] end) as $pairs
  | ([$pairs[] | (.[0] | anchors) - (.[1] | anchors)] | add // 0) as $lost
  | [$pairs[] | (.[0] | split("\n")) as $old | .[1] | split("\n")[]
     | select(IN($old[]) | not) | sub("^\\s+"; "")] as $added
  | [$added[] | select(test("HACK\\((?!https?://)"))] as $nourl
  | [$added[] | select(test("\\b(TODO|FIXME)\\b"))] as $todo
  | [
      (if $found != "" then
        "Anchors in \($dir) (read before editing; update the one above code you change):\n\($found)"
       else empty end),
      (if ($nourl + $todo) != [] then
        (["Comment warnings (not blocking):"]
         + [$nourl[] | "- \($hack) without an issue URL: \(.)\n  Write \($hack)<issue URL>): <what to remove once the issue is fixed>, or \($note): <the decision and the rejected alternative> for a choice that stays."]
         + [$todo[] | "- TODO/FIXME added: \(.)\n  A bare TODO is not an anchor. Track it in an issue and write \($hack)<issue URL>), or record a choice that stays as \($note)."])
        | join("\n")
       else empty end)
    ] as $ctx
  | {hookEventName: "PreToolUse"}
    + (if $lost > 0 then {
        permissionDecision: "ask",
        permissionDecisionReason: "This edit removes \($lost) anchor line(s) (\($hack) / \($note)). Anchors are not deleted unasked, except a HACK that leaves with the workaround it explains."
      } else {} end)
    + (if $ctx != [] then {additionalContext: ($ctx | join("\n\n"))} else {} end)
  | select(length > 1)
  | {hookSpecificOutput: .}
' <<<"$input"
