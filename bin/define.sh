#!/usr/bin/env bash

word=${1:-$(wl-paste -p 2>/dev/null)}

# Check for empty word or special characters
[[ -z "$word" || "$word" =~ [\/] ]] && notify-send -h string:bgcolor:#bf616a -t 3000 "Invalid input." && exit 0

query=$(curl -fsS --connect-timeout 5 --max-time 10 \
    --get "http://ustable.buru-ule.ts.net:8787/v1/query" \
    --data-urlencode "q=$word")

# Check for connection error
[ $? -ne 0 ] && notify-send -h string:bgcolor:#bf616a -t 3000 "Connection error." && exit 1

# Check for invalid word response
[[ "$query" == *"No Definitions Found"* ]] && notify-send -h string:bgcolor:#bf616a -t 3000 "Invalid word." && exit 0

# Check for no results or an invalid API response
jq -e '(.results // []) | length > 0' <<<"$query" >/dev/null 2>&1 || { notify-send -h string:bgcolor:#bf616a -t 3000 "No results found."; exit 0; }

# Show only first 3 definitions
def=$(jq -r '.results[] | "\n\(.headword) (\(.part_of_speech // "unknown")). \(.definition)"' <<<"$query")

# Send notification (KDE Plasma notification daemon will handle this)
notify-send -t 60000 "$word -" "$def"


# install wl-clipboard, jq from pacman
# original script source: https://github.com/BreadOnPenguins/scripts/blob/master/shortcuts-menus/define
