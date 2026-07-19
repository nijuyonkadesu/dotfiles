#!/bin/bash
# Notification hook — fires when Claude Code needs attention

# Prevent infinite loop: Stop hook can re-trigger Stop
INPUT=$(cat)
STOP_HOOK=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_HOOK" = "true" ] && exit 0

# Parse notification
TYPE=$(echo "$INPUT" | jq -r '.message // "needs your attention"' 2>/dev/null)

# Source env vars
source ~/.bashrc 2>/dev/null

# Send via notify.sh
tgnotify.sh "𓁹 ${TYPE}"
