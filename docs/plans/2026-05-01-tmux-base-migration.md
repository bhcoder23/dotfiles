# Tmux Base Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the user's base tmux workflow into this dotfiles repo as a Stow package, preserving the custom navigation/layout UX while removing current `agent-tracker` and `opencode` integration.

**Architecture:** Create a new `tmux` package rooted from `$HOME`, adapt the source `.tmux.conf` into a base-only version, copy only the required helper scripts, and replace agent/op-dependent status and pane-title scripts with standalone equivalents.

**Tech Stack:** GNU Stow, tmux 3.5a, shell scripts, Python helper scripts, repo documentation

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-tmux-base-migration-design.md`
- Create: `docs/plans/2026-05-01-tmux-base-migration.md`

**Step 1: Save the approved design**

Document:

- package layout
- kept base behavior
- removed agent/op behavior
- script reuse vs rewrite plan
- verification commands

### Task 2: Create The Tmux Package Skeleton

**Files:**
- Create: `tmux/.tmux.conf`
- Create: `tmux/.config/tmux/fzf_panes.tmux`
- Create: `tmux/.config/tmux/starship-tmux.toml`
- Create: `tmux/.config/tmux/scripts/*`
- Create: `tmux/.config/tmux/tmux-status/*`

**Step 1: Copy the base inputs**

Copy the main config, selected scripts, and selected status files into the new package tree.

**Step 2: Exclude unused agent/op files**

Do not migrate restore, tracker, popup, or agent task icon files that are not part of the base workflow.

### Task 3: Adapt `.tmux.conf` For Base-Only Use

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Remove agent/op hooks**

Delete hooks that invoke:

- `~/.config/agent-tracker/bin/agent`
- `restart_opencode_pane.sh`
- `post_resurrect_restore.sh`

**Step 2: Remove agent/op bindings**

Delete bindings for:

- agent palette
- task notifications
- watch mode
- op pane restart

**Step 3: Keep the core UX**

Retain:

- prefix and shell settings
- pane/window/session navigation
- copy-mode and clipboard
- layout and session helper bindings
- truecolor and styling
- TPM plugin definitions, but without the agent/op restore hook

### Task 4: Rewrite Status And Pane Title Helpers

**Files:**
- Modify: `tmux/.config/tmux/tmux-status/left.sh`
- Create or Modify: `tmux/.config/tmux/tmux-status/right.sh`
- Modify: `tmux/.config/tmux/scripts/pane_starship_title.sh`
- Modify: `tmux/.config/tmux/tmux-status/ccusage-today.sh`

**Step 1: Simplify the left status**

Keep only session list rendering and active-session highlighting.

**Step 2: Build a standalone right status**

Show:

- optional Codex daily cost if available
- current date/time

without requiring `agent-tracker`.

**Step 3: Simplify pane border titles**

Keep starship-based titles with safe fallback to command/path, but remove all `opencode` state logic.

**Step 4: Make Codex cost optional**

If `ccusage-codex` or `jq` is missing, print nothing instead of fake data.

### Task 5: Update Repo Metadata

**Files:**
- Modify: `README.md`

**Step 1: Add the tmux package**

Update package list, layout examples, and Stow commands to include `tmux`.

### Task 6: Activate The Package

**Files:**
- Verify only

**Step 1: Stow the package**

Run:

```bash
stow -d ~/dotfiles -t ~ tmux
```

Expected:

- `~/.tmux.conf` links to the repo
- `~/.config/tmux` links to the repo

### Task 7: Verify Tmux Loads The Config

**Files:**
- Verify: `tmux/.tmux.conf`
- Verify: `tmux/.config/tmux/scripts/*`
- Verify: `tmux/.config/tmux/tmux-status/*`

**Step 1: Check tmux config parsing**

Run:

```bash
tmux -L dotfiles-test -f ~/dotfiles/tmux/.tmux.conf start-server
tmux -L dotfiles-test show -g prefix
tmux -L dotfiles-test list-keys | rg 'open_shell_here|toggle_orientation|move_session|switch_session_by_index'
tmux -L dotfiles-test kill-server
```

Expected:

- server starts successfully
- prefix is `C-s`
- custom bindings are present

**Step 2: Check script syntax**

Run:

```bash
for f in tmux/.config/tmux/scripts/*.sh tmux/.config/tmux/tmux-status/*.sh; do bash -n "$f"; done
python3 -m py_compile tmux/.config/tmux/scripts/session_manager.py
```

Expected:

- no shell syntax errors
- Python helper compiles
