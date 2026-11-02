# Tests for autopilot.sh. `claude` is replaced by a stub (AUTOPILOT_CLAUDE) that
# records its argv and creates DONE on the call number given in STUB_DONE_AT.
# Run: bash test-autopilot.sh [path/to/autopilot.sh]
# shellcheck disable=SC2016  # negated greps run in `bash -c '...' _ arg` on purpose
set -euo pipefail

launcher=${1:-$(dirname "$0")/autopilot.sh}
launcher=$(cd "$(dirname "$launcher")" && pwd)/$(basename "$launcher") # the cases cd away
share=$(dirname "$launcher")
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
fails=0

stub=$root/claude
cat >"$stub" <<'EOF'
#!/usr/bin/env bash
# fake claude: log argv, bump a counter, create DONE when the counter reaches STUB_DONE_AT
n=$(( $(cat "$STUB_COUNT" 2>/dev/null || echo 0) + 1 ))
echo "$n" >"$STUB_COUNT"
printf '%s\n' "$*" >>"$STUB_LOG"
[[ -n ${STUB_DONE_AT:-} && $n -ge $STUB_DONE_AT ]] && touch .ai/autopilot/DONE
echo '{"session_id":"sid-123","result":"turn ended"}'
EOF
chmod +x "$stub"

check() { if "${@:2}"; then echo "ok   $1"; else
  echo "FAIL $1"
  fails=$((fails + 1))
fi; }

# project <name> -> a dir with a plan; stub state lives next to it
project() {
  local dir=$root/$1
  mkdir -p "$dir/.ai/plans"
  printf -- '- [ ] a\n' >"$dir/.ai/plans/p.md"
  echo "$dir"
}
launch() { # launch <dir> <done-at> <args...>
  local dir=$1 done_at=$2
  shift 2
  status=0
  out=$(cd "$dir" && STUB_COUNT=$dir/count STUB_LOG=$dir/argv STUB_DONE_AT=$done_at \
    AUTOPILOT_CLAUDE=$stub AUTOPILOT_SHARE=$share bash "$launcher" "$@" 2>&1) || status=$?
}
calls() { cat "$1/count" 2>/dev/null || echo 0; }

# 0-case: no plan -> usage, exit 2, claude never called
d=$(project none)
launch "$d" ""
check "no plan argument exits 2" test "$status" -eq 2
check "usage is printed" grep -q 'usage' <<<"$out"
check "claude is not called" test "$(calls "$d")" -eq 0

d=$(project missing)
launch "$d" "" .ai/plans/nope.md
check "missing plan file exits 2" test "$status" -eq 2

# 1-case: done on the first turn -> one call with the full flag set, CONDITIONS.md written
d=$(project one)
launch "$d" 1 -H 2 .ai/plans/p.md
check "finishes with 0 when DONE appears" test "$status" -eq 0
check "claude called once" test "$(calls "$d")" -eq 1
argv=$(cat "$d/argv")
check "starts the skill with the plan" grep -q -- '-p /autopilot .ai/plans/p.md' <<<"$argv"
check "passes the settings overlay" grep -q -- "--settings $share/settings.json" <<<"$argv"
check "passes the auditor" grep -q -- "--agents $share/agents.json" <<<"$argv"
check "appends the system prompt" grep -q -- "--append-system-prompt-file $share/system-prompt.md" <<<"$argv"
check "runs in auto permission mode" grep -q -- '--permission-mode auto' <<<"$argv"
check "answers no permission prompts" grep -q -- '--permission-prompts none' <<<"$argv"
cond=$d/.ai/autopilot/CONDITIONS.md
check "CONDITIONS.md names the plan" grep -qx 'plan: .ai/plans/p.md' "$cond"
started=$(sed -n 's/^started: //p' "$cond")
deadline=$(sed -n 's/^deadline: //p' "$cond")
check "deadline is started + 2h" test "$((deadline - started))" -eq 7200
audit=$(sed -n 's/^audit: //p' "$cond")
check "two audit slots at 50% and 85%" test "$audit" = "$((started + 3600)) $((started + 6120))"
check "session id is recorded" grep -qx 'session: sid-123' "$cond"

# N-case: done on the third turn -> two resumes of the same session
d=$(project three)
launch "$d" 3 -H 1 .ai/plans/p.md
check "claude called three times" test "$(calls "$d")" -eq 3
check "turns 2 and 3 resume the session" test "$(grep -c -- '--resume sid-123' "$d/argv")" -eq 2
check "first turn does not resume" bash -c '! head -1 "$1" | grep -q -- --resume' _ "$d/argv"

# deadline already reached after the first turn -> stop, report leftovers, non-zero
d=$(project late)
launch "$d" "" -H 0 .ai/plans/p.md
check "deadline stops the loop" test "$(calls "$d")" -eq 1
check "unfinished run exits 1" test "$status" -eq 1
check "leftovers are reported" grep -q -- '- \[ \] a' <<<"$out"

# a second launch archives the previous state instead of mixing runs
d=$(project again)
launch "$d" 1 -H 1 .ai/plans/p.md
launch "$d" 1 -H 1 .ai/plans/p.md
check "previous state is archived" test "$(find "$d/.ai/autopilot" -maxdepth 1 -name 'prev-*' | wc -l | tr -d ' ')" -eq 1
check "fresh DONE is not inherited" test "$(calls "$d")" -eq 2

echo
if ((fails)); then
  echo "$fails failing"
  exit 1
fi
echo "all passing"
