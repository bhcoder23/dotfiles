#!/usr/bin/env bash
set -euo pipefail

index="${1:-}"
client_name="${2:-}"

if [[ -z "$index" || ! "$index" =~ ^[0-9]+$ || "$index" -lt 1 ]]; then
  exit 0
fi

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
    awk -v target_index="$index" '
      NR == target_index {
        print $3
        exit
      }
    '
)"

[[ -n "$target_id" ]] || exit 0
if [[ -n "$client_name" ]]; then
  tmux switch-client -c "$client_name" -t "$target_id"
else
  tmux switch-client -t "$target_id"
fi
