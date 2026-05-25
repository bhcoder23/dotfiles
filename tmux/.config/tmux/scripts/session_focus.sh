#!/usr/bin/env bash
set -euo pipefail

direction="${1:-}"
current_id="${2:-}"
client_name="${3:-}"

case "$direction" in
  left|right) ;;
  *) exit 0 ;;
esac

if [[ -z "$current_id" ]]; then
  current_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
fi
current_id="${current_id#\\}"
[[ -n "$current_id" ]] || exit 0

sessions="$(tmux list-sessions -F $'#{session_id}\t#{session_name}\t#{session_created}' 2>/dev/null || true)"
[[ -n "$sessions" ]] || exit 0

target_id="$(
  printf '%s\n' "$sessions" |
    awk -F '\t' '
      NF >= 3 {
        name = $2
        if (name ~ /^[0-9]+-/) {
          session_index = name
          sub(/-.*/, "", session_index)
          printf "0 %010d %s\n", session_index, $1
        } else {
          printf "1 %010d %s\n", $3, $1
        }
      }
    ' |
    sort -k1,1n -k2,2n |
    awk -v current_id="$current_id" -v direction="$direction" '
      {
        ids[++count] = $3
      }
      END {
        for (i = 1; i <= count; i++) {
          if (ids[i] == current_id) {
            target = direction == "right" ? i + 1 : i - 1
            if (target > count) {
              target = 1
            } else if (target < 1) {
              target = count
            }
            print ids[target]
            exit
          }
        }
      }
    '
)"

[[ -n "$target_id" ]] || exit 0
if [[ -n "$client_name" ]]; then
  tmux switch-client -c "$client_name" -t "$target_id"
else
  tmux switch-client -t "$target_id"
fi
