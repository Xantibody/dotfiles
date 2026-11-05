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
felis=$root/felis
cat >"$felis" <<'EOF'
#!/usr/bin/env bash
# fake felis: log argv and any inherited Claude Code session marker, answer spawn with an id
printf '%s\n' "$*" >>"$FELIS_LOG"
env | grep -q '^CLAUDECODE=' && echo "leaked CLAUDECODE" >>"$FELIS_LOG"
[[ "$1 $2" == "sessions spawn" ]] && echo '{"v":1,"id":"0123456789abcdef0123456789abcdef"}'
exit 0
EOF
chmod +x "$felis"

# launch <dir> <done-at> <args...>; set in_felis=<id> first to run as if inside a felis session.
# The suite itself may run inside felis, so the real FELIS_SESSION_ID never leaks into a case.
in_felis=
launch() {
  local dir=$1 done_at=$2
  shift 2
  local session=()
  [[ -n $in_felis ]] && session=(FELIS_SESSION_ID="$in_felis")
  status=0
  out=$(cd "$dir" && env -u FELIS_SESSION_ID "${session[@]}" CLAUDECODE=1 \
    STUB_COUNT="$dir/count" STUB_LOG="$dir/argv" STUB_DONE_AT="$done_at" FELIS_LOG="$dir/felis" \
    AUTOPILOT_CLAUDE="$stub" AUTOPILOT_FELIS="$felis" AUTOPILOT_SHARE="$share" \
    bash "$launcher" "$@" 2>&1) || status=$?
}
calls() { cat "$1/count" 2>/dev/null || echo 0; }
felis_log() { cat "$1/felis" 2>/dev/null || true; }

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

# outside felis: no notification escape, felis never called
d=$(project plain)
launch "$d" 1 -H 1 .ai/plans/p.md
check "no OSC 9 outside felis" bash -c '! grep -q $'"'"'\e\]9;'"'"' <<<"$1"' _ "$out"
check "felis is not called outside felis" test -z "$(felis_log "$d")"

# inside felis, finished: OSC 9 says done and the session is tagged done
in_felis=fs-1
d=$(project notify-done)
launch "$d" 1 -H 1 .ai/plans/p.md
check "done run notifies through OSC 9" grep -q $'\e\\]9;autopilot: done' <<<"$out"
check "done run tags its session" grep -qx 'sessions tag fs-1 autopilot:done' <<<"$(felis_log "$d")"

# inside felis, unfinished: OSC 9 says stopped and the session is tagged stopped
d=$(project notify-stopped)
launch "$d" "" -H 0 .ai/plans/p.md
check "stopped run notifies through OSC 9" grep -q $'\e\\]9;autopilot: stopped' <<<"$out"
check "stopped run tags its session" grep -qx 'sessions tag fs-1 autopilot:stopped' <<<"$(felis_log "$d")"
in_felis=

# -d: hand the same run to a detached felis session and return at once
d=$(project detach)
launch "$d" 1 -d -H 2 -m opus .ai/plans/p.md
spawn=$(felis_log "$d")
check "-d exits 0" test "$status" -eq 0
check "-d does not run claude itself" test "$(calls "$d")" -eq 0
check "-d spawns a felis session tagged autopilot" grep -q -- '^sessions spawn .*--tag autopilot' <<<"$spawn"
check "-d starts the session in the project" grep -q -- "--cwd $d " <<<"$spawn"
check "-d carries PATH into the session" grep -q -- '--env PATH=' <<<"$spawn"
check "-d reruns itself without -d" grep -q -- "-- $launcher -H 2 -m opus .ai/plans/p.md\$" <<<"$spawn"
check "-d drops the Claude Code session markers" bash -c '! grep -q leaked <<<"$1"' _ "$spawn"
check "-d prints the session id" grep -q '0123456789abcdef0123456789abcdef' <<<"$out"

d=$(project detach-missing)
launch "$d" "" -d .ai/plans/nope.md
check "-d with a missing plan exits 2" test "$status" -eq 2
check "-d with a missing plan spawns nothing" test -z "$(felis_log "$d")"

echo
if ((fails)); then
  echo "$fails failing"
  exit 1
fi
echo "all passing"
