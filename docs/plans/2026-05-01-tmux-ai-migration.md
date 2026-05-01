# Tmux AI Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore the user's full tmux AI workflow from the source config into this dotfiles repo, while keeping startup and reload safe when `agent-tracker` or `opencode` are missing.

**Architecture:** Re-enable the source tmux hooks and keybindings, copy the missing AI helper scripts into the `tmux` Stow package, and patch the AI-dependent scripts so they degrade safely when optional tools are absent. Preserve existing repo fixes for tmux 3.5a compatibility and safe TPM loading.

**Tech Stack:** GNU Stow, tmux 3.5a, shell scripts, Python helper scripts, repo documentation

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-tmux-ai-migration-design.md`
- Create: `docs/plans/2026-05-01-tmux-ai-migration.md`

**Step 1: Save the approved design**

Document:

- restored AI behavior
- safe fallback policy
- files to copy and patch
- verification commands

### Task 2: Copy Missing AI Assets

**Files:**
- Create: `tmux/.config/tmux/scripts/open_agent_palette.sh`
- Create: `tmux/.config/tmux/scripts/watch_pane.sh`
- Create: `tmux/.config/tmux/scripts/restart_opencode_pane.sh`
- Create: `tmux/.config/tmux/scripts/post_resurrect_restore.sh`
- Create: `tmux/.config/tmux/scripts/restore_agent_run_panes.py`
- Create: `tmux/.config/tmux/scripts/restore_agent_tracker_mapping.py`
- Create: `tmux/.config/tmux/scripts/resurrect_op_session.sh`
- Create: `tmux/.config/tmux/tmux-status/notes_count.sh`
- Create: `tmux/.config/tmux/tmux-status/session_task_icon.sh`
- Create: `tmux/.config/tmux/tmux-status/window_task_icon.sh`
- Create: `tmux/.config/tmux/tmux-status/tracker_cache.sh`
- Create: `tmux/.config/tmux/tmux-status/mem_usage.sh`
- Create: `tmux/.config/tmux/tmux-status/mem_usage_cache.py`

**Step 1: Copy source AI files**

Copy the source files from `/Users/mason77/test/config/tmux/...` into the matching repo package paths.

**Step 2: Remove generated cache files**

Ensure no `__pycache__` or compiled artifacts remain in the package tree.

### Task 3: Restore AI Hooks And Keybindings

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Re-enable agent hooks**

Restore the source `agent-tracker` hook lines for:

- attach
- focus
- pane death
- session change
- window select

while making `refresh-client` safe in headless situations.

**Step 2: Re-enable AI keybindings**

Restore bindings for:

- `O`
- `M-s`
- `M-b`
- `M-w`
- `M-m`
- `M-M`
- `P`

**Step 3: Re-enable AI status and restore options**

Restore:

- `window_task_icon.sh` in window labels
- `@resurrect-hook-post-restore-all`

while keeping:

- `set -gq pane-scrollbars*`
- guarded TPM bootstrap

### Task 4: Patch Scripts For Safe Degradation

**Files:**
- Modify: `tmux/.config/tmux/scripts/open_agent_palette.sh`
- Modify: `tmux/.config/tmux/scripts/restart_opencode_pane.sh`
- Modify: `tmux/.config/tmux/scripts/post_resurrect_restore.sh`
- Modify: `tmux/.config/tmux/scripts/pane_starship_title.sh`
- Modify: `tmux/.config/tmux/scripts/resurrect_op_session.sh`
- Modify: `tmux/.config/tmux/tmux-status/right.sh`
- Modify: `tmux/.config/tmux/tmux-status/left.sh`
- Modify: `tmux/.config/tmux/tmux-status/window_task_icon.sh`
- Modify: `tmux/.config/tmux/tmux-status/notes_count.sh`

**Step 1: Guard missing agent/op binaries**

When external commands are missing:

- keep tmux usable
- show a short tmux message or silently skip
- avoid sending invalid commands into panes

**Step 2: Merge current fallback UX**

Preserve:

- current `right.sh` fallback time/cost display
- current `starship-tmux.toml` path in pane titles

### Task 5: Re-activate The Package

**Files:**
- Verify only

**Step 1: Restow the tmux package**

Run:

```bash
stow -R -d ~/dotfiles -t ~ tmux
```

Expected:

- `~/.tmux.conf` still points at repo
- `~/.config/tmux` still points at repo

### Task 6: Verify Tmux And AI Paths

**Files:**
- Verify: `tmux/.tmux.conf`
- Verify: `tmux/.config/tmux/scripts/*`
- Verify: `tmux/.config/tmux/tmux-status/*`

**Step 1: Verify config load and AI bindings**

Run:

```bash
tmux -L dotfiles-ai -f ~/dotfiles/tmux/.tmux.conf new-session -d -s verify
tmux -L dotfiles-ai source-file ~/.tmux.conf
tmux -L dotfiles-ai list-keys | rg 'open_agent_palette|watch_pane|restart_opencode|notifications_toggle'
tmux -L dotfiles-ai kill-server
```

Expected:

- no source-file errors
- AI keybindings are present

**Step 2: Verify missing dependency fallback**

Run:

```bash
PATH=/usr/bin:/bin tmux -L dotfiles-ai-fallback -f ~/dotfiles/tmux/.tmux.conf new-session -d -s verify
tmux -L dotfiles-ai-fallback source-file ~/.tmux.conf
tmux -L dotfiles-ai-fallback kill-server
```

Expected:

- tmux still starts
- no fatal config errors when optional tools are absent

**Step 3: Verify script syntax**

Run:

```bash
for f in tmux/.config/tmux/scripts/*.sh tmux/.config/tmux/tmux-status/*.sh; do bash -n "$f"; done
python3 -m py_compile tmux/.config/tmux/scripts/*.py tmux/.config/tmux/tmux-status/*.py
```

Expected:

- no shell syntax errors
- Python helpers compile
