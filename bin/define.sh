#!/usr/bin/env bash

word=${1:-$(wl-paste -p 2>/dev/null)}
word=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$word" | head -n1)

err() { notify-send -a Define -i dialog-error -u low -t 3000 "Define" "$1"; }

[[ -z "$word" || "$word" =~ [\/] ]] && err "Invalid input." && exit 0

query=$(curl -fsS --connect-timeout 5 --max-time 10 \
    --get "http://ustable.buru-ule.ts.net:8787/v1/query" \
    --data-urlencode "q=$word") || { err "Connection error."; exit 1; }

[[ "$query" == *"No Definitions Found"* ]] && err "Invalid word." && exit 0

jq -e '(.results // []) | length > 0' <<<"$query" >/dev/null 2>&1 \
    || { err "No results found."; exit 0; }

# Group: headword -> part of speech -> definitions (first-seen order, nothing dropped).
# One headword: it becomes the title and the body only shows parts of speech.
# Several headwords: title is what you searched, each headword gets a bold heading.
out=$(jq -c --arg word "$word" '
  def esc: gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
  def list:
    if length == 1 then "  " + (.[0] | esc)
    else to_entries | map("  \(.key + 1). \(.value | esc)") | join("\n")
    end;

  reduce .results[] as $r ({};
    .[$r.headword // $word][$r.part_of_speech // "unknown"] += [$r.definition]) as $g
  | ($g | length) as $n
  | {
      title: (if $n == 1 then ($g | keys_unsorted[0]) else $word end),
      body: (
        $g | to_entries | map(
          (if $n > 1 then "<b>\(.key | esc)</b>\n" else "" end) +
          (.value | to_entries
            | map("<i>\(.key | esc)</i>\n" + (.value | list))
            | join("\n"))
        ) | join("\n\n")
      )
    }
' <<<"$query")

title=$(jq -r .title <<<"$out")
body=$(jq -r .body <<<"$out")

notify-send -a Define -i accessories-dictionary -t 60000 \
    -h string:x-canonical-private-synchronous:define \
    "♪ $title" "$body"

# install wl-clipboard, jq from pacman
# original script source: https://github.com/BreadOnPenguins/scripts/blob/master/shortcuts-menus/define
