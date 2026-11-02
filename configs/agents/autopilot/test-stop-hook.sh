# Tests for stop-hook.sh. Each case builds a project dir under a temp root,
# pipes a Stop hook payload in, and checks the decision that comes out.
# Run: bash test-stop-hook.sh [path/to/stop-hook.sh]
# shellcheck disable=SC2016  # negated greps run in `bash -c '...' _ arg` on purpose
set -euo pipefail

hook=${1:-$(dirname "$0")/stop-hook.sh}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
fails=0
now=$(date +%s)

# project <name> <plan-body> <started> <deadline> <audit-epochs...>
project() {
  local dir=$root/$1
  mkdir -p "$dir/.ai/autopilot" "$dir/.ai/plans"
  printf '%s\n' "$2" >"$dir/.ai/plans/p.md"
  {
    echo "plan: .ai/plans/p.md"
    echo "started: $3"
    echo "deadline: $4"
    echo "audit: ${*:5}"
  } >"$dir/.ai/autopilot/CONDITIONS.md"
  echo "$dir"
}

run() { # run <dir> -> sets $out and $status (no subshell, so both survive)
  status=0
  out=$(jq -n --arg cwd "$1" '{cwd:$cwd, stop_hook_active:false, session_id:"s"}' | bash "$hook") || status=$?
}

check() { # check <name> <condition...>
  if "${@:2}"; then echo "ok   $1"; else
    echo "FAIL $1"
    fails=$((fails + 1))
  fi
}
decision() { jq -r '.decision // "allow"' <<<"$1"; }
reason() { jq -r '.reason // ""' <<<"$1"; }

# 0-case: not an autopilot session -> stays silent, allows the stop
mkdir -p "$root/plain"
run "$root/plain"
check "no CONDITIONS.md allows stop" test "$status" -eq 0 -a -z "$out"

# 1-case: one unchecked item -> block, and name the item
d=$(project one $'- [x] done thing\n- [ ] open thing' "$now" "$((now + 3600))")
run "$d"
check "unchecked item blocks" test "$(decision "$out")" = block
check "reason names the open item" grep -q 'open thing' <<<"$(reason "$out")"
check "reason does not list the done item" bash -c '! grep -q "done thing" <<<"$1"' _ "$(reason "$out")"

# all checked but no DONE marker -> still block, ask for the marker
d=$(project nomarker $'- [x] a' "$now" "$((now + 3600))")
run "$d"
check "all checked without DONE blocks" test "$(decision "$out")" = block
check "reason mentions DONE" grep -q 'DONE' <<<"$(reason "$out")"

# all checked and DONE -> allow
d=$(project finished $'- [x] a\n- [x] b' "$now" "$((now + 3600))")
touch "$d/.ai/autopilot/DONE"
run "$d"
check "DONE with all checked allows stop" test "$status" -eq 0 -a -z "$out"

# DONE but an item is still open -> the marker is a lie: remove it, block
d=$(project liar $'- [ ] a' "$now" "$((now + 3600))")
touch "$d/.ai/autopilot/DONE"
run "$d"
check "premature DONE blocks" test "$(decision "$out")" = block
check "premature DONE is removed" test ! -e "$d/.ai/autopilot/DONE"

# deadline passed -> allow, whatever the plan says
d=$(project late $'- [ ] a' "$((now - 7200))" "$((now - 60))")
run "$d"
check "past deadline allows stop" test "$status" -eq 0 -a -z "$out"

# N-case: an audit slot has passed -> block once with the audit instruction, then not again
d=$(project audit $'- [ ] a' "$((now - 3600))" "$((now + 3600))" "$((now - 60))" "$((now + 1800))")
run "$d"
check "due audit blocks with auditor instruction" grep -q 'auditor' <<<"$(reason "$out")"
run "$d"
check "second stop after audit goes back to plan items" bash -c '! grep -q auditor <<<"$1"' _ "$(reason "$out")"
check "future audit slot is left pending" test "$(wc -l <"$d/.ai/autopilot/audited" | tr -d ' ')" -eq 1

# a malformed CONDITIONS.md must never wedge the session: allow
mkdir -p "$root/broken/.ai/autopilot"
echo "garbage" >"$root/broken/.ai/autopilot/CONDITIONS.md"
run "$root/broken"
check "malformed conditions allow stop" test "$status" -eq 0

echo
if ((fails)); then
  echo "$fails failing"
  exit 1
fi
echo "all passing"
