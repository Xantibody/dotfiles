# Claude Code Stop hook for an autopilot session.
# Keeps the agent working until the plan is done or the deadline passes, and
# turns the mid-run audits into hook output instead of a hope that the model
# remembers. Reads .ai/autopilot/CONDITIONS.md written by `autopilot`:
#   plan: <path to the plan, relative to cwd>
#   started: <epoch>
#   deadline: <epoch>
#   audit: <epoch> [<epoch> ...]
# Decisions, in order:
#   no CONDITIONS.md / unparsable  -> allow (never wedge a session that is not ours)
#   deadline passed                -> allow (the launcher reports the leftovers)
#   an audit slot passed, unrun    -> block: run the auditor subagent (once per slot)
#   DONE present but items open    -> remove DONE, block
#   items open                     -> block, listing them
#   all checked, no DONE           -> block: run the final checks, then create DONE
#   all checked and DONE           -> allow
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // "."' <<<"$input")
state=$cwd/.ai/autopilot
conditions=$state/CONDITIONS.md
[[ -f $conditions ]] || exit 0

field() { sed -n "s/^$1:[[:space:]]*//p" "$conditions" | head -1; }
plan_rel=$(field plan)
deadline=$(field deadline)
audits=$(field audit)
[[ -n $plan_rel && $deadline =~ ^[0-9]+$ ]] || exit 0
plan=$cwd/$plan_rel
[[ -f $plan ]] || exit 0

now=$(date +%s)
((now < deadline)) || exit 0
left=$(((deadline - now) / 60))

block() {
  jq -n --arg r "$1" '{decision:"block", reason:$r}'
  exit 0
}

# Audits: one block per slot whose time has come. `audited` records the slots already run.
audited=$state/audited
touch "$audited"
for slot in $audits; do
  [[ $slot =~ ^[0-9]+$ ]] || continue
  ((slot <= now)) || continue
  grep -qx "$slot" "$audited" && continue
  echo "$slot" >>"$audited"
  block "Audit time (${left} min left until the deadline). Do not end the turn. Start the \`auditor\` subagent now: it reads $plan_rel and .ai/autopilot/journal.md and returns the decisions that lack evidence or contradict the plan. Act on its findings, note what you changed in journal.md, then continue with the plan."
done

open=$(grep -E '^\s*- \[ \]' "$plan" | sed -E 's/^\s*- \[ \] ?//' || true)
done_marker=$state/DONE

if [[ -n $open ]]; then
  if [[ -e $done_marker ]]; then
    rm -f "$done_marker"
    block "DONE was created while $plan_rel still has unchecked items; removed it. Finish them first:"$'\n'"$open"
  fi
  block "Plan not finished (${left} min left). Do not end the turn. Unchecked items in $plan_rel:"$'\n'"$open"$'\n'"Take the first one, implement it with the \`implement\` skill, tick it off, write the decision to .ai/autopilot/journal.md, and keep going. If an item cannot be done, write why in journal.md and mark it [x] with a note rather than stopping."
fi

[[ -e $done_marker ]] && exit 0
block "Every item in $plan_rel is checked but .ai/autopilot/DONE does not exist. Run the \`check\` skill, then the \`history-review\` skill; if both pass, create .ai/autopilot/DONE and write the closing summary to .ai/autopilot/journal.md. If something fails, fix it first."
