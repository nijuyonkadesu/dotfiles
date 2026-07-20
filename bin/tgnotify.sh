#!/bin/bash
#
# tgnotify.sh — Claude Code notification dispatcher.
#
# A staged pipeline (see main() at the bottom). Each stage owns ONE concern and
# publishes its result into documented global "records" — bash has no structs —
# namespaced by prefix:
#   EV_*   parsed invocation intent   (parse_args)
#   CTX_*  runtime context            (detect_platform / detect_scope)
#   G_*    shared 5h-clock state       (load_global)
#   L_*    per-scope local state       (load_local)
#   DEC_*  state-machine decision      (decide)
#   MSG_*  composed message parts      (compose_*)
#
# ── ONE: event kinds (decided purely by invocation flags) ────────────────
#   notify     --bar + MSG    (Stop hook:         "𓋹 task completed")  bar,  tail
#   attention  MSG, no --bar  (Notification hook: "𓁹 …")               no bar, tail
#   reminder   --reminder     (internal, fired by the idle timer)       bar,  no tail
#
# ── TWO: time frames (from the LOCAL session clock) ──────────────────────
#   active  elapsed ≤ 5h, gap < 50m
#   idle    elapsed ≤ 5h, gap ≥ 50m      → reminder becomes eligible
#   expired elapsed > 5h                 → reset local + global (new session)
#
# ── THREE/FOUR: run env → state scope ────────────────────────────────────
#   inside tmux  → key + header = tmux SESSION name (shared by its panes)
#   outside tmux → key + header = last two dirs (e.g. .config/dotfiles)
#   _global (one file, all scopes) holds the shared 5h clock → drives the bar.
#
# ── FIVE: platform → backend ────────────────────────────────────────────
#   macOS → plain text  → osascript banner
#   Linux → HTML        → curl Telegram sendMessage
#
# Decision table (decide):
#   kind\frame        active            idle                     expired
#   notify/attention  send·adv·sched·persist  (same)             send·RESET·sched·persist
#   reminder          no-op             send (read-only)         no-op
#
# STATE IS WRITTEN ONLY IF DELIVERY SUCCEEDS (never in --debug).
#
# Local state file:  first_time last_time count reminder_pid intervals...
# Global state file: global_first_time last_write_time

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────
WARNING=3000        # 50m — idle threshold that arms the reminder
TIMEOUT=18000       # 5h  — session lifetime; past this, reset
BAR_WIDTH=20
STATE_DIR="${TGNOTIFY_STATE_DIR:-/tmp/notify_state}"
GLOBAL_STATE_FILE="${STATE_DIR}/_global"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
SOUND="${CLAUDE_CODE_NOTIFY_SOUND:-Glass}"

GLYPH_REMINDER="𓇳"
REMINDER_TEXT="session idle 50m"

# ── Pure helpers ─────────────────────────────────────────────────────────
clock() { date +%s; }

fmt_time() {        # seconds → 45s / 2m30s / 1h05m
  local s=$1
  if   [ "$s" -lt 60 ];   then printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '%dm%ds' $((s/60)) $((s%60))
  else printf '%dh%dm' $((s/3600)) $(((s%3600)/60)); fi
}

fmt_interval() {    # seconds → ·45s / ·2m / ·1h
  local s=$1
  if   [ "$s" -lt 60 ];   then printf '·%ds' "$s"
  elif [ "$s" -lt 3600 ]; then printf '·%dm' $((s/60))
  else printf '·%dh' $((s/3600)); fi
}

html_escape() {     # only render_html uses this
  local s=$1
  s="${s//&/\&amp;}"; s="${s//</\&lt;}"; s="${s//>/\&gt;}"
  printf '%s' "$s"
}

# Reap a reminder subshell AND its child sleep (killing only the subshell would
# orphan the sleep for up to 50m).
cancel_reminder() {
  local pid=$1
  [ -n "$pid" ] && [ "$pid" != "0" ] || return 0
  pkill -P "$pid" 2>/dev/null || true
  kill "$pid" 2>/dev/null || true
}

schedule_reminder() {
  ( sleep "$WARNING" && "$SCRIPT_PATH" --reminder ) >/dev/null 2>&1 &
  echo $!
}

# ── Stage: parse_args → EV_* ─────────────────────────────────────────────
parse_args() {
  EV_KIND="attention"; EV_WITH_BAR=0; EV_SHOW_TAIL=1
  EV_HOLD=0; EV_DEBUG=0; EV_MSG=""
  local had_bar=0 had_reminder=0 a
  local args=()
  for a in "$@"; do
    case "$a" in
      --help|-h)  EV_KIND="help";  return 0 ;;
      --reset)    EV_KIND="reset"; return 0 ;;
      --reminder) had_reminder=1 ;;
      --bar)      had_bar=1 ;;
      --event)    EV_HOLD=1 ;;
      --debug)    EV_DEBUG=1 ;;
      *)          args+=("$a") ;;
    esac
  done
  [ "${#args[@]}" -gt 0 ] && EV_MSG="${args[0]}"

  if [ "$had_reminder" -eq 1 ]; then
    EV_KIND="reminder"; EV_WITH_BAR=1; EV_SHOW_TAIL=0
    EV_MSG="${GLYPH_REMINDER} ${REMINDER_TEXT}"
  elif [ "$had_bar" -eq 1 ]; then
    EV_KIND="notify"; EV_WITH_BAR=1; EV_SHOW_TAIL=1
  else
    EV_KIND="attention"; EV_WITH_BAR=0; EV_SHOW_TAIL=1
  fi
}

# ── Stage: detect_platform → CTX_PLATFORM ────────────────────────────────
detect_platform() {
  case "$(uname -s)" in
    Darwin) CTX_PLATFORM="macos" ;;
    *)      CTX_PLATFORM="linux" ;;
  esac
}

# ── Stage: detect_scope → CTX_INTMUX, CTX_LABEL (display), CTX_ID (key) ───
detect_scope() {
  if [ -n "${TMUX:-}" ]; then
    CTX_INTMUX=1
    local s=""
    s=$(tmux display-message -p -t "${TMUX_PANE:-}" '#{session_name}' 2>/dev/null) || s=""
    if [ -z "$s" ]; then
      s=$(tmux list-panes -a -F '#{pane_id} #{session_name}' 2>/dev/null \
          | awk -v p="${TMUX_PANE:-}" '$1==p{print $2; exit}') || s=""
    fi
    [ -z "$s" ] && s="tmux_${TMUX_PANE:-unknown}"
    CTX_LABEL="$s"
  else
    CTX_INTMUX=0
    local cwd; cwd=$(pwd)
    CTX_LABEL="$(basename "$(dirname "$cwd")")/$(basename "$cwd")"
  fi
  CTX_ID="${CTX_LABEL//[^A-Za-z0-9._-]/_}"
}

# ── Stage: load_global → G_FIRST (start of shared 5h window) ──────────────
load_global() {
  local now=$1 g=""
  if [ -s "$GLOBAL_STATE_FILE" ]; then
    read -r g _ < "$GLOBAL_STATE_FILE" || g=""
    case "$g" in ''|*[!0-9]*) g="" ;; esac
  fi
  if [ -z "$g" ] || [ $((now - g)) -gt "$TIMEOUT" ]; then
    G_FIRST=$now          # missing or >5h old → the window restarts now
  else
    G_FIRST=$g
  fi
}

# ── Stage: load_local → L_FIRST L_LAST L_COUNT L_PID L_INTERVALS[] L_FRAME ─
load_local() {
  local id=$1 now=$2
  local f="${STATE_DIR}/${id}"
  L_FIRST=$now; L_LAST=$now; L_COUNT=0; L_PID="0"; L_INTERVALS=(); L_EXISTS=0
  if [ -s "$f" ]; then
    local st=()
    st=($(cat "$f")) || st=()
    if [ "${#st[@]}" -ge 4 ]; then
      L_FIRST="${st[0]}"; L_LAST="${st[1]}"; L_COUNT="${st[2]}"; L_PID="${st[3]}"
      [ "${#st[@]}" -gt 4 ] && L_INTERVALS=("${st[@]:4}")
      L_EXISTS=1
    fi
  fi
  local elapsed=$((now - L_FIRST)) gap=$((now - L_LAST))
  if   [ "$elapsed" -gt "$TIMEOUT" ]; then L_FRAME="expired"
  elif [ "$gap" -ge "$WARNING" ];     then L_FRAME="idle"
  else                                     L_FRAME="active"
  fi
}

# ── Stage: decide → DEC_SEND DEC_RESET DEC_ADVANCE DEC_SCHEDULE DEC_PERSIST ─
decide() {
  local kind=$1 frame=$2
  DEC_SEND=0; DEC_RESET=0; DEC_ADVANCE=0; DEC_SCHEDULE=0; DEC_PERSIST=0
  case "$kind" in
    reminder)
      [ "$frame" = "idle" ] && DEC_SEND=1     # read-only: no persist/schedule
      ;;
    notify|attention)
      DEC_SEND=1; DEC_SCHEDULE=1; DEC_PERSIST=1
      if [ "$frame" = "expired" ]; then DEC_RESET=1; else DEC_ADVANCE=1; fi
      ;;
  esac
  return 0    # never let a trailing false test make this function "fail" under set -e
}

# ── Stage: apply_transition → mutate L_* / G_* in memory, set G_ELAPSED ───
apply_transition() {
  local now=$1
  if [ "$DEC_RESET" -eq 1 ]; then
    L_FIRST=$now; L_COUNT=1; L_INTERVALS=()
    G_FIRST=$now                                   # >5h → restart shared clock
  elif [ "$DEC_ADVANCE" -eq 1 ]; then
    if [ "$EV_HOLD" -eq 1 ]; then
      [ "$L_COUNT" -lt 1 ] && L_COUNT=1            # --event: hold the tally
    else
      L_COUNT=$((L_COUNT + 1))
      [ "$L_EXISTS" -eq 1 ] && L_INTERVALS=(${L_INTERVALS[@]+"${L_INTERVALS[@]}"} "$((now - L_LAST))")
    fi
  fi
  [ "$L_COUNT" -lt 1 ] && L_COUNT=1
  L_LAST=$now
  G_ELAPSED=$((now - G_FIRST)); [ "$G_ELAPSED" -lt 0 ] && G_ELAPSED=0
  return 0    # trailing false test must not make this function "fail" under set -e
}

# ── Stage: compose_* → platform-agnostic message parts ───────────────────
compose_title() { printf '%s' "$1"; }             # $1 = EV_MSG (already glyphed)

compose_tail() {                                   # "#N·i1·i2" (last 5 intervals)
  local count=$1; shift
  local intervals=("$@") tail="#${count}" i
  local n="${#intervals[@]}" start
  if [ "$n" -gt 0 ]; then
    start=$((n - 5)); [ "$start" -lt 0 ] && start=0
    for i in "${intervals[@]:$start}"; do tail="${tail}$(fmt_interval "$i")"; done
  fi
  printf '%s' "$tail"
}

compose_header() {                                 # "☑ label (tmux)·hostname" | "☑ label·hostname"
  if [ "$CTX_INTMUX" -eq 1 ]; then printf '☑ %s (tmux)·%s' "$1" "$(hostname)"
  else printf '☑ %s·%s' "$1" "$(hostname)"; fi
}

compose_bar() {                                    # "▓▓░░ 45% [2h30m]"
  local elapsed=$1
  local filled=$((elapsed * BAR_WIDTH / TIMEOUT))
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  [ "$filled" -lt 0 ] && filled=0
  local empty=$((BAR_WIDTH - filled)) pct=$((elapsed * 100 / TIMEOUT))
  [ "$pct" -gt 100 ] && pct=100
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  printf '%s %d%% [%s]' "$bar" "$pct" "$(fmt_time "$elapsed")"
}

compose_body() {                                   # → MSG_BODY[] (below the tail)
  local with_bar=$1 header=$2 gelapsed=$3
  if [ "$with_bar" -eq 1 ]; then
    MSG_BODY=("$header" "$(compose_bar "$gelapsed")")
  else
    MSG_BODY=("${header} · $(fmt_time "$gelapsed")")
  fi
}

# ── Stage: render (per platform) ─────────────────────────────────────────
render_html() {                                    # Telegram payload
  local out line
  out="<b>$(html_escape "$MSG_TITLE")</b>"
  [ -n "$MSG_TAIL" ] && out="${out}
<code>$(html_escape "$MSG_TAIL")</code>"
  for line in "${MSG_BODY[@]}"; do
    out="${out}
$(html_escape "$line")"
  done
  printf '%s' "$out"
}

render_plain_body() {                              # osascript body (no title line)
  local body="" line
  [ -n "$MSG_TAIL" ] && body="$MSG_TAIL"
  for line in "${MSG_BODY[@]}"; do
    if [ -n "$body" ]; then body="${body}
${line}"; else body="$line"; fi
  done
  printf '%s' "$body"
}

# ── Stage: send (per backend) ────────────────────────────────────────────
send_macos() {
  osascript - "Claude Code" "$MSG_TITLE" "$(render_plain_body)" "$SOUND" >/dev/null 2>&1 <<'OSA'
on run argv
  display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv) sound name (item 4 of argv)
end run
OSA
}

send_telegram() {
  local resp
  resp=$(curl -s --max-time 10 -X POST \
    "https://api.telegram.org/bot${CLAUDE_CODE_NOTIFY_APIKEY:-}/sendMessage" \
    -d chat_id="${CLAUDE_CODE_NOTIFY_TO_USERID:-}" \
    --data-urlencode "text=$(render_html)" \
    -d parse_mode="HTML") || return 1
  [ "$(jq -r '.ok // false' <<<"$resp" 2>/dev/null)" = "true" ]
}

# ── Stage: deliver (routes by platform; --debug prints instead) ──────────
deliver() {
  if [ "$EV_DEBUG" -eq 1 ]; then
    {
      echo "── [debug] platform=${CTX_PLATFORM} scope=${CTX_ID} kind=${EV_KIND} frame=${L_FRAME:-n/a} ──"
      if [ "$CTX_PLATFORM" = "macos" ]; then
        echo "title: ${MSG_TITLE}"; render_plain_body; echo
      else
        render_html; echo
      fi
      echo "────────────────────────────────────────────────────────────"
    } >&2
    return 0
  fi
  if [ "$CTX_PLATFORM" = "macos" ]; then send_macos; else send_telegram; fi
}

# ── Stage: persist (only when the decision says so) ──────────────────────
persist_state() {
  [ "$DEC_PERSIST" -eq 1 ] || return 0
  mkdir -p "$STATE_DIR"
  local pid="$L_PID" f="${STATE_DIR}/${CTX_ID}"
  if [ "$DEC_SCHEDULE" -eq 1 ]; then
    cancel_reminder "$L_PID"
    pid=$(schedule_reminder)
  fi
  if [ "${#L_INTERVALS[@]}" -gt 0 ]; then
    echo "$L_FIRST $L_LAST $L_COUNT $pid ${L_INTERVALS[*]}" > "$f"
  else
    echo "$L_FIRST $L_LAST $L_COUNT $pid" > "$f"
  fi
  echo "$G_FIRST $L_LAST" > "$GLOBAL_STATE_FILE"
}

# ── Commands (non-pipeline) ──────────────────────────────────────────────
print_usage() {
  cat <<'EOF'
Usage: tgnotify.sh [OPTIONS] [MESSAGE]
  -h, --help   Show this help
  --reset      Clear this scope's state (and cancel its reminder)
  --event      Send but hold the ping counter
  --debug      Print the rendered payload instead of sending
  --bar        Include the session progress bar (notify)
  --reminder   Internal: fired by the background idle timer
EOF
}

do_reset() {
  local f="${STATE_DIR}/${CTX_ID}" pid=""
  if [ -f "$f" ]; then
    read -r _ _ _ pid _ < "$f" || pid=""
    cancel_reminder "${pid:-0}"
    rm -f "$f"
  fi
  echo "State cleared for scope: ${CTX_ID}"
}

# ── main: the pipeline ───────────────────────────────────────────────────
main() {
  parse_args "$@"
  [ "$EV_KIND" = "help" ] && { print_usage; exit 0; }

  detect_platform
  detect_scope
  [ "$EV_KIND" = "reset" ] && { do_reset; exit 0; }

  mkdir -p "$STATE_DIR"
  local now; now=$(clock)
  load_global "$now"
  load_local "$CTX_ID" "$now"

  decide "$EV_KIND" "$L_FRAME"
  [ "$DEC_SEND" -eq 1 ] || exit 0          # reminder no-op cases

  apply_transition "$now"

  MSG_TITLE=$(compose_title "$EV_MSG")
  if [ "$EV_SHOW_TAIL" -eq 1 ]; then
    MSG_TAIL=$(compose_tail "$L_COUNT" ${L_INTERVALS[@]+"${L_INTERVALS[@]}"})
  else
    MSG_TAIL=""
  fi
  MSG_HEADER=$(compose_header "$CTX_LABEL")
  compose_body "$EV_WITH_BAR" "$MSG_HEADER" "$G_ELAPSED"

  # Persist ONLY on a real, successful send — never in --debug.
  if deliver && [ "$EV_DEBUG" -eq 0 ]; then persist_state; fi
}

main "$@"

