#!/usr/bin/env bash
set -euo pipefail

agent_bin="$HOME/.config/agent-tracker/bin/agent"
if [[ -x "$agent_bin" ]]; then
  exec "$agent_bin" tmux right-status "$@"
fi

parts=()

ccusage_script="$HOME/.config/tmux/tmux-status/ccusage-today.sh"
if [[ -x "$ccusage_script" ]]; then
  ccusage="$("$ccusage_script" 2>/dev/null || true)"
  if [[ -n "$ccusage" ]]; then
    parts+=("$ccusage")
  fi
fi

parts+=("$(date '+%Y-%m-%d %H:%M')")

printf ' %s ' "$(IFS=' | '; echo "${parts[*]}")"
