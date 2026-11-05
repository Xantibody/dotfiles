# autopilot: run Claude Code unattended until a .ai/plans/ checklist is done.
#
#   autopilot [-d] [-H hours] [-m model] <plan.md>
#
# -d hands the same run to a detached felis session and returns its id at once, so
# a Claude Code session (or a closed window) can start a run without waiting on it.
# Attach with `felis attach <id>`; the run notifies and tags the session when it ends.
#
# Writes .ai/autopilot/CONDITIONS.md (plan, start, deadline, audit slots), starts a
# headless session with `/autopilot <plan>`, and resumes that session every time a
# turn ends until .ai/autopilot/DONE exists or the deadline passes. The Stop hook
# (stop-hook.sh, installed through settings.json) does the in-turn pushing; this
# loop only covers the case where the harness let a turn end anyway.
#
# AUTOPILOT_SHARE  dir holding settings.json / agents.json / system-prompt.md
#                  (default: this script's dir)
# AUTOPILOT_CLAUDE claude binary (default: claude); the tests point it at a stub
# AUTOPILOT_FELIS  felis binary (default: felis); the tests point it at a stub
# AUTOPILOT_BUDGET_USD  optional --max-budget-usd per turn
set -euo pipefail

usage() {
  echo "usage: autopilot [-d] [-H hours] [-m model] <plan.md>" >&2
  exit 2
}

detach=
hours=4
model=
while getopts 'dH:m:' opt; do
  case $opt in
  d) detach=1 ;;
  H) hours=$OPTARG ;;
  m) model=$OPTARG ;;
  *) usage ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -eq 1 ]] || usage
plan=$1
[[ -f $plan ]] || {
  echo "autopilot: plan not found: $plan" >&2
  usage
}
[[ $hours =~ ^[0-9]+$ ]] || {
  echo "autopilot: -H takes whole hours" >&2
  usage
}

share=${AUTOPILOT_SHARE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
claude_bin=${AUTOPILOT_CLAUDE:-claude}
felis_bin=${AUTOPILOT_FELIS:-felis}

if [[ -n $detach ]]; then
  self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
  args=(-H "$hours")
  [[ -n $model ]] && args+=(-m "$model")
  # A launch from inside Claude Code carries its session markers (CLAUDECODE and
  # friends), and a claude that sees them treats itself as nested. The run is a
  # session of its own, so drop every CLAUDE* variable before felis copies the env.
  drop=()
  while read -r var; do drop+=(-u "$var"); done < <(env | sed -n 's/^\(CLAUDE[A-Za-z0-9_]*\)=.*/\1/p')
  # PATH is passed explicitly: a daemon started by launchd or systemd has a minimal one,
  # and the run needs claude, git and the project's tools.
  id=$(env "${drop[@]}" "$felis_bin" sessions spawn --format json --tag autopilot \
    --cwd "$PWD" --env "PATH=$PATH" -- "$self" "${args[@]}" "$plan" | jq -r .id)
  echo "autopilot: running $plan in felis session $id"
  echo "attach: felis attach $id"
  exit 0
fi
state=.ai/autopilot
conditions=$state/CONDITIONS.md
done_marker=$state/DONE

# A previous run's state would make the Stop hook see a stale DONE or audit list.
if [[ -e $conditions ]]; then
  prev=$state/prev-$(date +%s)
  mkdir -p "$prev"
  find "$state" -maxdepth 1 -type f -exec mv {} "$prev/" \;
fi
mkdir -p "$state"

started=$(date +%s)
total=$((hours * 3600))
deadline=$((started + total))
{
  echo "plan: $plan"
  echo "started: $started"
  echo "deadline: $deadline"
  echo "audit: $((started + total / 2)) $((started + total * 85 / 100))"
} >"$conditions"

common=(
  --settings "$share/settings.json"
  --agents "$share/agents.json"
  --append-system-prompt-file "$share/system-prompt.md"
  --permission-mode auto
  --permission-prompts none
  --output-format json
)
[[ -n $model ]] && common+=(--model "$model")
[[ -n ${AUTOPILOT_BUDGET_USD:-} ]] && common+=(--max-budget-usd "$AUTOPILOT_BUDGET_USD")

turn() { # turn <prompt> [extra flags...] -> prints the result JSON, returns claude's status
  local prompt=$1
  shift
  "$claude_bin" -p "$prompt" "${common[@]}" "$@"
}

log=$state/runs.log
failures=0
session=

echo "autopilot: $plan, ${hours}h until $(date -r "$deadline" '+%H:%M' 2>/dev/null || date -d "@$deadline" '+%H:%M')"
out=$(turn "/autopilot $plan") || failures=$((failures + 1))
printf '%s\n' "$out" >>"$log"
session=$(jq -r '.session_id // empty' <<<"$out" 2>/dev/null || true)
[[ -n $session ]] && echo "session: $session" >>"$conditions"

while [[ ! -e $done_marker ]] && (($(date +%s) < deadline)); do
  if ((failures >= 3)); then
    echo "autopilot: claude failed $failures times in a row, giving up" >&2
    break
  fi
  if [[ -z $session ]]; then
    echo "autopilot: no session id to resume, giving up" >&2
    break
  fi
  if out=$(turn "The previous turn ended. Reread $conditions and $plan, then continue with the first unchecked item." --resume "$session"); then
    failures=0
  else
    failures=$((failures + 1))
  fi
  printf '%s\n' "$out" >>"$log"
done

# finish <done|stopped> <message>: inside a felis session, raise an OSC 9 notification
# (the felis relay shows it once the window is gone) and tag the session so
# `felis sessions list --tag autopilot:<outcome>` finds the finished runs.
finish() {
  [[ -n ${FELIS_SESSION_ID:-} ]] || return 0
  printf '\e]9;autopilot: %s\a' "$2"
  "$felis_bin" sessions tag "$FELIS_SESSION_ID" "autopilot:$1" >/dev/null 2>&1 || true
}

name=$(basename "$plan")
if [[ -e $done_marker ]]; then
  echo "autopilot: done. Journal: $state/journal.md"
  finish "done" "done $name"
  exit 0
fi
echo "autopilot: stopped before the plan was finished. Left in $plan:"
grep -E '^\s*- \[ \]' "$plan" || true
finish "stopped" "stopped $name, $(grep -cE '^\s*- \[ \]' "$plan" || true) items left"
exit 1
