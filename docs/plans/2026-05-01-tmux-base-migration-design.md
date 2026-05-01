# Tmux Base Migration Design

## Goal

Migrate the user's working `tmux` setup from `/Users/mason77/test/config/.tmux.conf` and its helper scripts into this dotfiles repo as a proper GNU Stow package, while keeping only the base tmux workflow and removing current `agent-tracker` and `opencode` integration.

## Current State

- The repo currently has no `tmux` Stow package.
- The source tmux setup consists of:
  - a main config file at `/Users/mason77/test/config/.tmux.conf`
  - helper scripts under `/Users/mason77/test/config/tmux/scripts`
  - status scripts under `/Users/mason77/test/config/tmux/tmux-status`
  - a pane picker script at `/Users/mason77/test/config/tmux/fzf_panes.tmux`
- The main config mixes three concerns:
  1. core tmux behavior
  2. custom window/pane/session navigation helpers
  3. `agent-tracker` and `opencode`-specific hooks, status, and restore behavior

## Chosen Approach

Create a new `tmux` Stow package rooted from `$HOME` and migrate only the base tmux workflow:

1. Add a new package with:
   - `tmux/.tmux.conf`
   - `tmux/.config/tmux/fzf_panes.tmux`
   - `tmux/.config/tmux/scripts/...`
   - `tmux/.config/tmux/tmux-status/...`
   - `tmux/.config/tmux/starship-tmux.toml`
2. Keep the user's custom workflow for:
   - prefix and navigation
   - pane splitting and layout helpers
   - session ordering and switching
   - clipboard integration
   - pane selection via `fzf`
   - pane border titles and status bar styling
3. Remove or disable:
   - `agent-tracker` hooks
   - `agent` popup/notification bindings
   - `opencode` pane restart and restore hooks
   - task/watch/question status logic tied to `agent` / `op`
4. Keep status scripts and pane title rendering, but rewrite them to be self-contained and not depend on `agent-tracker` or `opencode`.

## Package Layout

The tmux package will mirror `$HOME`:

- `tmux/.tmux.conf`
- `tmux/.config/tmux/fzf_panes.tmux`
- `tmux/.config/tmux/starship-tmux.toml`
- `tmux/.config/tmux/scripts/`
- `tmux/.config/tmux/tmux-status/`

This matches the repo convention that each tool is its own Stow package rooted from `$HOME`.

## What Stays

### Core tmux behavior

- `Ctrl-s` as prefix
- mouse support
- `xterm-keys`, focus events, extended keys, passthrough
- `zsh` as default shell
- history, base indexes, renumbering, title updates
- truecolor terminal setup

### Navigation and layout workflow

- split pane shortcuts using `u/e/n/i`
- pane movement with `M-n`, `M-e`, `M-u`, `M-i`
- window navigation with `M-l`, `M-y`, `C-p`, `C-n`
- numbered session switching and window moves
- layout builder helpers
- pane focus helpers by geometric position
- `fzf` pane switcher

### Clipboard and copy-mode workflow

- vi copy-mode keys
- copy to system clipboard
- paste from system clipboard

### Session management helpers

- ordered session naming and renaming
- new session helper
- move session left/right
- move window to another session

### Presentation

- colored pane borders
- pane border titles using a simplified starship-based renderer
- left status for session list
- right status for time and optional Codex cost

## What Gets Removed

### Agent-tracker integration

Remove:

- hooks that call `~/.config/agent-tracker/bin/agent`
- popup palette bindings
- notification and acknowledge bindings
- task icons in session/window status
- watch/unread/task state logic

### OpenCode integration

Remove:

- pane restart bindings for `op` / `opencode`
- resurrect restore scripts specific to `opencode`
- pane title state derived from `opencode`

### Unused status helpers

Do not wire in scripts that exist only for agent-driven state, such as:

- `notes_count.sh`
- `session_task_icon.sh`
- `window_task_icon.sh`
- `tracker_cache.sh`
- post-restore agent scripts

## Script Strategy

### Reuse as-is where possible

Copy these scripts with minimal or no changes:

- `fzf_panes.tmux`
- `check_and_run_on_activate.sh`
- `copy_to_clipboard.sh`
- `focus_pane_by_position.sh`
- `layout_builder.sh`
- `move_session.sh`
- `move_window_to_session.sh`
- `new_session.sh`
- `open_shell_here.sh`
- `paste_from_clipboard.sh`
- `rename_session_prompt.sh`
- `session_created.sh`
- `session_manager.py`
- `swap_window_in_session.sh`
- `switch_session_by_index.sh`
- `toggle_orientation.sh`
- `update_theme_color.sh`

### Rewrite for base-only behavior

Create simplified versions of:

- `tmux/.config/tmux/tmux-status/left.sh`
- `tmux/.config/tmux/tmux-status/right.sh`
- `tmux/.config/tmux/scripts/pane_starship_title.sh`
- `tmux/.config/tmux/tmux-status/ccusage-today.sh`

These scripts should degrade safely when optional tools are unavailable.

## Plugin Policy

Keep TPM support, but do not require it for config loading:

- keep `tmux-resurrect`
- keep `tmux-continuum`
- remove agent/op post-restore hook
- guard TPM initialization so config still loads if TPM is missing

## Verification

The migration is complete when:

- `stow -d ~/dotfiles -t ~ tmux` creates `~/.tmux.conf` and `~/.config/tmux/...`
- `tmux -L dotfiles-test -f ~/dotfiles/tmux/.tmux.conf start-server` succeeds
- `tmux -L dotfiles-test show -g prefix` reports `C-s`
- `tmux -L dotfiles-test list-keys` shows the expected custom bindings
- the config no longer references `agent-tracker` or `opencode`
- the status scripts and pane title script execute without hard dependency failures
