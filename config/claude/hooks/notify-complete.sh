#!/bin/bash
# Stop hook — fires when Claude Code finishes a task

# Prevent infinite loop: Stop hook can re-trigger Stop
INPUT=$(cat)
STOP_HOOK=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_HOOK" = "true" ] && exit 0

# Parse stop info
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_hook_active // "completed"' 2>/dev/null)

# Source env vars
source ~/.bashrc 2>/dev/null

# Send via notify.sh
tgnotify.sh --bar "𓋹 task completed"
