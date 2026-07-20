#!/bin/bash

# ╔═════════════════════════════════════════════════════════════════════╗
# ║                    STATE MACHINE TRUTH TABLE                        ║
# ╠═══════════╦══════════════╦══════════╦═══════════════════════════════╣
# ║   MODE    ║ SESSION_EXP  ║ GAP≥50m  ║ ACTION                        ║
# ╠═══════════╬══════════════╬══════════╬═══════════════════════════════╣
# ║ NORMAL    ║      0       ║    X     ║ send, update state,           ║
# ║           ║              ║          ║ schedule reminder             ║
# ║ NORMAL    ║      1       ║    X     ║ reset, send, update state,    ║
# ║           ║              ║          ║ schedule reminder             ║
# ║ REMINDER  ║      0       ║    0     ║ no-op (user active)           ║
# ║ REMINDER  ║      0       ║    1     ║ send reminder, no state chg   ║
# ║ REMINDER  ║      1       ║    X     ║ no-op (session expired)       ║
# ╠═══════════╬══════════════╬══════════╬═══════════════════════════════╣
# ║ --reset   ║      X       ║    X     ║ kill reminder, remove state   ║
# ║ --help    ║      X       ║    X     ║ print usage, exit             ║
# ╚═══════════╩══════════════╩══════════╩═══════════════════════════════╝
#
# --event: same as NORMAL, but COUNT/INTERVALS are held instead of
#          advanced — used for passive hook pings that shouldn't
#          inflate the session ping tally.
#
# THRESHOLDS:
#   WARNING  = 3000s  (50 min)
#   TIMEOUT  = 18000s (5 hr)
#
# STATE FILE: first_time last_time count reminder_pid intervals...
#   - Normal:   write ALL fields after successful curl
#   - Reminder: read-only, never written
#   - Per-pane (keyed by TERM_ID): COUNT/INTERVALS/GAP/local FIRST_TIME —
#     the ping tally and cadence history are local to each terminal.
#
# GLOBAL STATE FILE (_global): global_first_time last_write_time
#   Shared by every pane. Drives the 5hr reset + the bar/elapsed display
#   only — whichever pane pings first after 5hr of silence *anywhere*
#   starts the global clock; every pane's bar reflects that same clock.

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────
WARNING=3000
TIMEOUT=18000
STATE_DIR="${TGNOTIFY_STATE_DIR:-/tmp/notify_state}"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
DEBUG_MODE=0

# ── Helpers ────────────────────────────────────────────────────────────
fmt_time() {
  local s=$1
  if   [ "$s" -lt 60 ];  then printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '%dm%ds' $((s/60)) $((s%60))
  else printf '%dh%dm' $((s/3600)) $(((s%3600)/60))
  fi
}

fmt_interval() {
  local s=$1
  if   [ "$s" -lt 60 ];  then printf '·%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '·%dm' $((s/60))
  else printf '·%dh' $((s/3600))
  fi
}

cancel_reminder() {
  local pid=$1
  if [ -n "$pid" ] && [ "$pid" != "0" ]; then
    kill "$pid" 2>/dev/null || true
  fi
}

# Echo the global clock's start time, or nothing if _global is absent, empty,
# or corrupt — notably the brief 0-byte window while another pane rewrites it
# (echo > file truncates before writing). Without this, `read` on that empty
# file returns non-zero and set -e would kill the notification. Callers apply
# their own fallback when the result is empty.
read_global_first() {
  [ -s "$GLOBAL_STATE_FILE" ] || return 0
  local g=""
  read -r g _ < "$GLOBAL_STATE_FILE" || return 0
  case "$g" in
    ''|*[!0-9]*) return 0 ;;
    *) printf '%s' "$g" ;;
  esac
}

html_escape() {
  # An unescaped & in the replacement of ${var//pat/repl} means "insert
  # the matched text" (like sed's &) — so &lt;/&gt; must be written as
  # \&lt;/\&gt; or bash drops the literal ampersand.
  local s=$1
  s="${s//&/\&amp;}"
  s="${s//</\&lt;}"
  s="${s//>/\&gt;}"
  printf '%s' "$s"
}

# Strip the HTML markup (used for Telegram) back to plain text for native
# macOS notifications, which have no markup. Tags are removed and the three
# entities produced by html_escape are reversed (&amp; last, mirroring the
# escape order in html_escape).
strip_html() {
  local s
  s=$(printf '%s' "$1" | sed -E 's/<[^>]*>//g')
  s="${s//&lt;/<}"
  s="${s//&gt;/>}"
  s="${s//&amp;/&}"
  printf '%s' "$s"
}

# macOS backend: native Notification Center banner via osascript. Works
# offline and is never subject to the corporate web gateway.
send_msg_macos() {
  local plain title subtitle body sound
  plain=$(strip_html "$1")
  title="Claude Code"
  # First line is the event headline; the remaining lines are the details.
  subtitle=$(printf '%s\n' "$plain" | sed -n '1p')
  # Keep the remaining lines as real newlines so the progress bar renders on
  # its own line in the notification instead of being mashed onto one line.
  body=$(printf '%s\n' "$plain" | sed '1d')
  sound="${CLAUDE_CODE_NOTIFY_SOUND:-Glass}"
  # Pass the strings as argv rather than interpolating them into the
  # AppleScript source, so quotes/backslashes in the message can neither
  # break the script nor inject AppleScript.
  osascript - "$title" "$subtitle" "$body" "$sound" >/dev/null 2>&1 <<'OSA' || return 1
on run argv
  display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv) sound name (item 4 of argv)
end run
OSA
}

# Telegram backend: used on non-macOS hosts (e.g. Linux).
send_msg_telegram() {
  local resp
  resp=$(curl -s --max-time 10 -X POST "https://api.telegram.org/bot${CLAUDE_CODE_NOTIFY_APIKEY}/sendMessage" \
    -d chat_id="${CLAUDE_CODE_NOTIFY_TO_USERID}" \
    --data-urlencode "text=$1" \
    -d parse_mode="HTML") || return 1
  [ "$(jq -r '.ok // false' <<<"$resp" 2>/dev/null)" = "true" ]
}

send_msg() {
  local backend="telegram"
  if [ "$(uname -s)" = "Darwin" ]; then backend="macos"; fi

  if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "── [debug] backend=${backend} ──" >&2
    echo "text:" >&2
    echo "$1" >&2
    echo "──────────────────────────────────────────────────────────────" >&2
    return 0
  fi

  if [ "$backend" = "macos" ]; then
    send_msg_macos "$1"
  else
    send_msg_telegram "$1"
  fi
}

schedule_reminder() {
  ( sleep "$WARNING" && "$SCRIPT_PATH" --reminder ) >/dev/null 2>&1 &
  echo $!
}

build_header() {
  HEADER="☑ $(basename "$(pwd)")"
  if [ -n "${TMUX:-}" ]; then
    HEADER="${HEADER} (tmux)"
  fi
  HEADER="${HEADER} $(hostname)"
}

build_bar() {
  local elapsed=$1
  local bar_w=20
  local filled=$((elapsed * bar_w / TIMEOUT))
  local empty=$((bar_w - filled))
  BAR=""
  for ((i=0; i<filled; i++)); do BAR="${BAR}▓"; done
  for ((i=0; i<empty; i++)); do BAR="${BAR}░"; done
  ELAPSED_STR=$(fmt_time "$elapsed")
  PCT=$((elapsed * 100 / TIMEOUT))
}

# ── Terminal ID ────────────────────────────────────────────────────────
if [ -n "${TMUX_PANE:-}" ]; then
  # TMUX_PANE (e.g. %152) is tmux's own stable, never-reused pane id —
  # unlike #{window_index}.#{pane_index}, it doesn't shift when other
  # windows are opened/closed/reordered in the same session.
  TERM_ID="${TMUX_PANE#%}"
else
  # `tty` inspects fd 0, which is a pipe when invoked from a Claude Code
  # hook — read the controlling terminal from the process table instead,
  # which stays valid even when stdin/stdout are redirected.
  TERM_ID=$(ps -o tty= -p $$ 2>/dev/null | tr -d '[:space:]' | tr '/' '_')
  if [ -z "$TERM_ID" ] || [ "$TERM_ID" = "?" ]; then
    TERM_ID="no_tty_$$"
  fi
fi

STATE_FILE="${STATE_DIR}/${TERM_ID}"
GLOBAL_STATE_FILE="${STATE_DIR}/_global"
mkdir -p "$STATE_DIR"

# ── --help ─────────────────────────────────────────────────────────────
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: notify.sh [OPTIONS] [MESSAGE]"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help"
  echo "  --reset        Clear session state and exit"
  echo "  --event        Send without advancing the ping counter"
  echo "  --debug        Print the would-be request instead of sending it"
  echo "  --bar          Include the full session progress bar"
  exit 0
fi

# ── --reset ────────────────────────────────────────────────────────────
if [ "${1:-}" = "--reset" ]; then
  if [ -f "$STATE_FILE" ]; then
    read -r _ _ _ REMAIN < "$STATE_FILE"
    cancel_reminder "${REMAIN%% *}"
    rm -f "$STATE_FILE"
  fi
  echo "State cleared."
  exit 0
fi

# ── --reminder (internal, invoked by background sleep) ─────────────────
if [ "${1:-}" = "--reminder" ]; then
  [ -f "$STATE_FILE" ] || exit 0

  NOW=$(date +%s)
  STATE=($(cat "$STATE_FILE"))
  FIRST_TIME=${STATE[0]}
  LAST_TIME=${STATE[1]}

  SESSION_ELAPSED=$((NOW - FIRST_TIME))
  GAP=$((NOW - LAST_TIME))

  # SESSION_EXPIRED=1 → no-op (this check stays local to this pane)
  [ "$SESSION_ELAPSED" -gt "$TIMEOUT" ] && exit 0
  # GAP < 50min → user active, no-op
  [ "$GAP" -lt "$WARNING" ] && exit 0

  # Send reminder — the bar reflects the global clock (shared across
  # every pane), read-only here since --reminder never writes state.
  GLOBAL_FIRST_TIME=$FIRST_TIME
  G_FIRST=$(read_global_first)
  [ -n "$G_FIRST" ] && GLOBAL_FIRST_TIME=$G_FIRST
  [ $((NOW - GLOBAL_FIRST_TIME)) -gt "$TIMEOUT" ] && GLOBAL_FIRST_TIME=$NOW
  GLOBAL_ELAPSED=$((NOW - GLOBAL_FIRST_TIME))

  build_header
  build_bar "$GLOBAL_ELAPSED"
  MSG="<b>𓇳 session idle 50m</b>
${HEADER}
${BAR} ${PCT}% [${ELAPSED_STR}]"
  send_msg "$MSG"
  exit 0
fi

# ── Normal invocation ──────────────────────────────────────────────────
# Flags are recognized in any position (before or after the message),
# since `cmd "message" --bar` is just as natural to type as `cmd --bar
# "message"` — only whatever's left after pulling flags out becomes $1.
EVENT_MODE=0
BAR_MODE=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --event) EVENT_MODE=1 ;;
    --debug) DEBUG_MODE=1 ;;
    --bar)   BAR_MODE=1 ;;
    *) ARGS+=("$arg") ;;
  esac
done
set -- "${ARGS[@]}"

NOW=$(date +%s)
COUNT=1
INTERVALS=()
OLD_PID=""

if [ -f "$STATE_FILE" ]; then
  STATE=($(cat "$STATE_FILE"))
  FIRST_TIME=${STATE[0]}
  LAST_TIME=${STATE[1]}
  PREV_COUNT=${STATE[2]}
  OLD_PID=${STATE[3]}
  PREV_INTERVALS=("${STATE[@]:4}")

  [ "$DEBUG_MODE" -eq 1 ] || cancel_reminder "$OLD_PID"

  if [ $((NOW - FIRST_TIME)) -gt "$TIMEOUT" ]; then
    FIRST_TIME=$NOW
  elif [ "$EVENT_MODE" -eq 1 ]; then
    COUNT=$PREV_COUNT
    INTERVALS=("${PREV_INTERVALS[@]}")
  else
    COUNT=$((PREV_COUNT + 1))
    ELAPSED=$((NOW - LAST_TIME))
    INTERVALS=("${PREV_INTERVALS[@]}" "$ELAPSED")
  fi
else
  FIRST_TIME=$NOW
fi

# ── Build message ──────────────────────────────────────────────────────
# ${arr[@]: -5} silently returns empty when the array has fewer than 5
# elements (bash's negative-offset slice goes below 0 and gives up), so
# clamp the start index instead of relying on the negative form.
DISPLAY_START=$(( ${#INTERVALS[@]} - 5 ))
[ "$DISPLAY_START" -lt 0 ] && DISPLAY_START=0
DISPLAY="${INTERVALS[@]:$DISPLAY_START}"
TAIL="#${COUNT}"
for I in $DISPLAY; do
  TAIL="${TAIL}$(fmt_interval "$I")"
done

# ── Global clock (shared 5hr window + bar, across every pane) ──────────
GLOBAL_FIRST_TIME=$NOW
G_FIRST=$(read_global_first)
if [ -n "$G_FIRST" ] && [ $((NOW - G_FIRST)) -le "$TIMEOUT" ]; then
  GLOBAL_FIRST_TIME=$G_FIRST
fi
GLOBAL_ELAPSED=$((NOW - GLOBAL_FIRST_TIME))

build_header

if [ "$BAR_MODE" -eq 1 ]; then
  build_bar "$GLOBAL_ELAPSED"
  TAIL_LINE="${HEADER}
${BAR} ${PCT}% [${ELAPSED_STR}]"
else
  ELAPSED_STR=$(fmt_time "$GLOBAL_ELAPSED")
  TAIL_LINE="${HEADER} · ${ELAPSED_STR}"
fi

MESSAGE="<b>$(html_escape "$1")</b>
<code>${TAIL}</code>
${TAIL_LINE}"

# ── Send & update state ───────────────────────────────────────────────
if send_msg "$MESSAGE" && [ "$DEBUG_MODE" -ne 1 ]; then
  NEW_PID=$(schedule_reminder)
  if [ ${#INTERVALS[@]} -gt 0 ]; then
    echo "$FIRST_TIME $NOW $COUNT $NEW_PID ${INTERVALS[*]}" > "$STATE_FILE"
  else
    echo "$FIRST_TIME $NOW $COUNT $NEW_PID" > "$STATE_FILE"
  fi
  echo "$GLOBAL_FIRST_TIME $NOW" > "$GLOBAL_STATE_FILE"
fi
