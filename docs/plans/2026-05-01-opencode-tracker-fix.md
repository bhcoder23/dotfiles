# OpenCode Tracker Fix

## Goal

Restore the missing `opencode` dotfiles package so `op` sessions can drive tmux / `agent-tracker` status icons again.

## Root Cause

- `tmux` and `agent-tracker` were migrated.
- The source `opencode` config was not migrated.
- `op` launched with `OP_TRACKER_NOTIFY=1`, but the temp config did not include the tracker TUI plugin or extra tool files.
- Result: the pane ran `opencode`, but `agent tracker state` stayed `Active 0 · Waiting 0`.

## Fix

- Add a managed `opencode/.config/opencode` package.
- Merge the current provider config into tracked `opencode.json`.
- Restore source `AGENTS.md`, `agents`, `command`, `tool`, `tools`, `tui-plugins`, `tui.json`, and `consult.json`.
- Update `_op_common.zsh` so temp OpenCode homes copy these files and folders.
- Enable tracker forwarding for `se` and `opr` too.

## Verification

- `~/.config/opencode` contains the restored plugin and tool files.
- New `op` sessions receive the extra config in their temp `OPENCODE_CONFIG_DIR`.
- `tracker-notify.ts` can set tmux pane state and call `agent tracker command`.
