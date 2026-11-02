# Tests for compact-hook.sh. Run: bash test-compact-hook.sh [path/to/compact-hook.sh]
# shellcheck disable=SC2016  # negated greps run in `bash -c '...' _ arg` on purpose
set -euo pipefail

hook=${1:-$(dirname "$0")/compact-hook.sh}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
fails=0

check() { if "${@:2}"; then echo "ok   $1"; else
  echo "FAIL $1"
  fails=$((fails + 1))
fi; }
run() {
  status=0
  out=$(jq -n --arg cwd "$1" '{cwd:$cwd, source:"compact"}' | bash "$hook") || status=$?
}

# 0-case: no autopilot state -> silent
mkdir -p "$root/plain"
run "$root/plain"
check "no CONDITIONS.md prints nothing" test "$status" -eq 0 -a -z "$out"

# 1-case: a run with open items -> conditions and the open items come back
d=$root/open
mkdir -p "$d/.ai/autopilot" "$d/.ai/plans"
printf -- '- [x] done\n- [ ] still open\n' >"$d/.ai/plans/p.md"
printf 'plan: .ai/plans/p.md\ndeadline: 1\n' >"$d/.ai/autopilot/CONDITIONS.md"
run "$d"
check "conditions are reinjected" grep -q 'deadline: 1' <<<"$out"
check "open items are listed" grep -q 'still open' <<<"$out"
check "done items are not" bash -c '! grep -q "\[x\] done" <<<"$1"' _ "$out"

# all checked -> points at the finishing steps instead of an empty list
d=$root/finished
mkdir -p "$d/.ai/autopilot" "$d/.ai/plans"
printf -- '- [x] done\n' >"$d/.ai/plans/p.md"
printf 'plan: .ai/plans/p.md\n' >"$d/.ai/autopilot/CONDITIONS.md"
run "$d"
check "finished plan asks for DONE" grep -q 'DONE' <<<"$out"

echo
if ((fails)); then
  echo "$fails failing"
  exit 1
fi
echo "all passing"
