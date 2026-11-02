# Claude Code SessionStart hook (matcher: compact) for an autopilot session.
# After a compaction the model keeps a summary, not the files it was told to
# reread. Put the run's conditions and the open plan items back in front of it.
set -euo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // "."' <<<"$input")
conditions=$cwd/.ai/autopilot/CONDITIONS.md
[[ -f $conditions ]] || exit 0

plan_rel=$(sed -n 's/^plan:[[:space:]]*//p' "$conditions" | head -1)
plan=$cwd/$plan_rel
open=
[[ -f $plan ]] && open=$(grep -E '^\s*- \[ \]' "$plan" || true)

{
  echo "Autopilot run in progress; context was just compacted. Conditions:"
  cat "$conditions"
  echo
  if [[ -n $open ]]; then
    echo "Unchecked items in $plan_rel:"
    echo "$open"
  else
    echo "All items in $plan_rel are checked; finish with the check and history-review skills, then create .ai/autopilot/DONE."
  fi
  echo "Continue from the first unchecked item. Decisions go to .ai/autopilot/journal.md."
}
