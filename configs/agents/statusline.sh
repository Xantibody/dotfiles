#!/usr/bin/env bash
#
# Two rows: where the session is (directory, branch, PR), then which model
# runs it and how much of each budget is spent.

# One jq pass, one value per line, read back in the same order.
{
  read -r dir
  read -r model
  read -r effort
  read -r fast
  read -r ctx_pct
  read -r h5_pct
  read -r h5_reset
  read -r d7_pct
  read -r d7_reset
  read -r pr_number
  read -r pr_url
  read -r pr_state
} < <(jq -r '
  .workspace.current_dir // .cwd // "",
  .model.display_name // "",
  .effort.level // "",
  .fast_mode // false,
  .context_window.used_percentage // 0,
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.five_hour.resets_at // "",
  .rate_limits.seven_day.used_percentage // "",
  .rate_limits.seven_day.resets_at // "",
  .pr.number // "",
  .pr.url // "",
  .pr.review_state // ""
')

RESET=$'\033[0m'
DIM=$'\033[2m'
# Bright black, not dim: dim washes out on a light background.
MUTED=$'\033[90m'
SEP=" ${DIM}│${RESET} "

usage_color() {
  if [ "$1" -ge 90 ]; then
    printf '\033[31m'
  elif [ "$1" -ge 70 ]; then
    printf '\033[33m'
  else
    printf '\033[32m'
  fi
}

time_left() {
  local left=$(($1 - $(date +%s)))
  if [ "$left" -ge 86400 ]; then
    printf '%dd%dh' $((left / 86400)) $((left % 86400 / 3600))
  elif [ "$left" -ge 3600 ]; then
    printf '%dh%dm' $((left / 3600)) $((left % 3600 / 60))
  elif [ "$left" -gt 0 ]; then
    printf '%dm' $((left / 60))
  fi
}

# A five-cell bar, so three of them still fit on one row. The empty cells
# are outlines rather than ░, which all but vanishes on a light background.
meter() {
  local label=$1 pct=$2 i filled color
  filled=$(((pct + 10) / 20))
  color=$(usage_color "$pct")
  printf '%s %s' "$label" "$color"
  for ((i = 0; i < filled; i++)); do printf '■'; done
  printf '%s' "$MUTED"
  for ((i = filled; i < 5; i++)); do printf '□'; done
  printf ' %s%d%%%s' "$color" "$pct" "$RESET"
}

# Absent windows print nothing: the five-hour one is not on every plan.
rate_limit() {
  local label=$1 pct=$2 reset=$3
  [ -n "$pct" ] || return
  pct=$(printf '%.0f' "$pct")
  printf '%s%s' "$SEP" "$(meter "$label" "$pct")"
  if [ -n "$reset" ]; then
    local left
    left=$(time_left "$reset")
    [ -n "$left" ] && printf ' %s󰔟 %s%s' "$MUTED" "$left" "$RESET"
  fi
}

# --- Row 1: where -------------------------------------------------------

where="󰉋 ${dir##*/}"

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
if [ -z "$branch" ]; then
  # Detached HEAD, or not a repository at all (then this is empty too).
  branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
fi
# md-source_branch, escaped: an editor or a tool may drop a raw glyph.
[ -n "$branch" ] && where+="  "$'\U000F062C'" ${branch}"

if [ -n "$pr_number" ]; then
  case "$pr_state" in
  approved) pr_color=$'\033[32m' ;;
  changes_requested) pr_color=$'\033[31m' ;;
  pending) pr_color=$'\033[33m' ;;
  *) pr_color=$DIM ;;
  esac
  # OSC 8 makes the number clickable in terminals that support hyperlinks.
  # md-source_pull
  where+="  ${pr_color}"$'\U000F04C2 \033]8;;'"${pr_url}"$'\033\\'"#${pr_number}"$'\033]8;;\033\\'"${RESET}"
fi

# --- Row 2: model and budgets ------------------------------------------

usage="󰚩 ${model}"
[ -n "$effort" ] && usage+=" ${DIM}·${RESET} ${effort}"
[ "$fast" = "true" ] && usage+=$' \033[33m󱐋\033[0m'

usage+="${SEP}$(meter 󰧑 "$(printf '%.0f' "$ctx_pct")")"

usage+=$(rate_limit 󱑏 "$h5_pct" "$h5_reset")
usage+=$(rate_limit 󰨳 "$d7_pct" "$d7_reset")

printf '%s\n%s\n' "$where" "$usage"
