#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Get token info from context_window (provided via stdin JSON)
used_percentage=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_tokens=$((total_input + total_output))

# Format token display
if [ "$total_tokens" -ge 1000 ]; then
  thousands=$(echo "scale=1; $total_tokens/1000" | bc)
  token_display=$(printf "%.1fK" "$thousands")
else
  token_display="$total_tokens"
fi

# Color coding for percentage
if [ "$used_percentage" -ge 90 ]; then
  color="\033[31m" # Red
elif [ "$used_percentage" -ge 70 ]; then
  color="\033[33m" # Yellow
else
  color="\033[32m" # Green
fi

TOKEN_COUNT=$(echo -e "${token_display} tkns. (${color}${used_percentage}%\033[0m)")

# Weekly rate limit, present only for claude.ai subscribers after the first response
WEEKLY=""
weekly_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
weekly_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$weekly_pct" ]; then
  weekly_pct=$(printf "%.0f" "$weekly_pct")
  if [ "$weekly_pct" -ge 90 ]; then
    weekly_color="\033[31m"
  elif [ "$weekly_pct" -ge 70 ]; then
    weekly_color="\033[33m"
  else
    weekly_color="\033[32m"
  fi
  WEEKLY=" | 󰃰 7d ${weekly_color}${weekly_pct}%\033[0m"
  if [ -n "$weekly_reset" ]; then
    left=$((weekly_reset - $(date +%s)))
    if [ "$left" -ge 3600 ]; then
      WEEKLY="${WEEKLY} ($((left / 86400))d$((left % 86400 / 3600))h)"
    elif [ "$left" -gt 0 ]; then
      WEEKLY="${WEEKLY} ($((left / 60))m)"
    fi
  fi
  WEEKLY=$(echo -e "$WEEKLY")
fi

echo "󰚩 ${MODEL_DISPLAY} | 󰉋 ${CURRENT_DIR##*/} | 󰧑 ${TOKEN_COUNT}${WEEKLY}"
