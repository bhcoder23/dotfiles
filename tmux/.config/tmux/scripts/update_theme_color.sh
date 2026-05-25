#!/usr/bin/env bash
set -euo pipefail

tmux_env() {
  local name="$1"
  local fallback="$2"
  local line

  line=$(tmux show-environment "$name" 2>/dev/null || true)
  if [[ "$line" == "$name="* ]]; then
    printf '%s' "${line#*=}"
    return
  fi

  line=$(tmux show-environment -g "$name" 2>/dev/null || true)
  if [[ "$line" == "$name="* ]]; then
    printf '%s' "${line#*=}"
    return
  fi

  printf '%s' "$fallback"
}

theme="$(tmux_env TMUX_THEME_COLOR "#d9ba73")"
theme_bg="$(tmux_env TMUX_THEME_BG "#090909")"
theme_surface="$(tmux_env TMUX_THEME_SURFACE "#1a1a1a")"
theme_fg="$(tmux_env TMUX_THEME_FG "#b0b0b0")"
theme_muted="$(tmux_env TMUX_THEME_MUTED "#50585d")"

# Cache as user options and apply status styles
tmux set -g @theme_color "$theme"
tmux set -g @theme_bg "$theme_bg"
tmux set -g @theme_surface "$theme_surface"
tmux set -g @theme_fg "$theme_fg"
tmux set -g @theme_muted "$theme_muted"
tmux set -g status-bg "$theme_bg"
tmux set -g pane-active-border-style "fg=$theme"

exit 0
