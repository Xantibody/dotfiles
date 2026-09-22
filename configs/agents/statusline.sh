#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Get git branch information
GIT_BRANCH=""
if git -C "$CURRENT_DIR" rev-parse &>/dev/null; then
  BRANCH=$(git -C "$CURRENT_DIR" branch --show-current 2>/dev/null)
  if [ -n "$BRANCH" ]; then
    GIT_BRANCH=" |  $BRANCH"
  else
    COMMIT_HASH=$(git -C "$CURRENT_DIR" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$COMMIT_HASH" ]; then
      GIT_BRANCH=" |  HEAD ($COMMIT_HASH)"
    fi
  fi
fi

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

echo "󰚩 ${MODEL_DISPLAY} |  ${CURRENT_DIR##*/}${GIT_BRANCH} |  ${TOKEN_COUNT}"
